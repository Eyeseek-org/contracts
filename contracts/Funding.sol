// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Chain donation contract
/// @author Michal Kazdan

contract Funding is Ownable, ReentrancyGuard {
    IERC20 public usdc;
    IERC20 public usdt;
    IERC20 public dai;
    /// TBD  axlUSDC to add if implementation would be successful
    /// TBD new events to watch - negative scenarios - error log
    /// TBD for each currency needed to separate general functions, ideally create a library


    address public feeAddress = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    uint256 public minAmount = 1;
    uint256 public platformFee = 1;
   

    /// @notice Use modifiers to check when deadline is passed
    modifier isDeadlinePassed(uint256 _id) {
        require(
            block.timestamp < funds[_id].deadline,
            "Deadline for crowdfunding has passed."
        );
        _;
    }

    /// @notice Main crowdfunding fund
    /// @dev TBD would be also good to implement reward counter and cap in the future
    struct Fund {
        uint256 id;
        address owner;
        uint256 balance;
        uint256 deadline; // Timespan for crowdfunding to be active
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
        uint256 level1;
        uint256 tokenReward;
        address tokenRewardAddress;
        uint256 usdcBalance;
        uint256 usdtBalance;
        uint256 daiBalance;
    }

    /// @notice Unlimited amount of microfunds could be connect with a main fund
    struct MicroFund {
        uint256 microId;
        address owner;
        uint256 cap;
        uint256 microBalance;
        uint256 fundId;
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
        uint256 currency;  
        ///@notice 0=Eye, 1=USDC, 2=USDT, 3=DAI
    }

    /// @dev Struct for direct donations
    struct Donate {
        uint256 id;
        uint256 fundId;
        address backer;
        uint256 amount;
        uint256 state; ///@dev 0=Donated, 1=Distributed, 2=Refunded
        uint256 currency; ///@notice 0=Eye, 1=USDC, 2=USDT, 3=DAI
    }

    /// @dev Struct for ERC1155 NFT rewards
    struct RewardPool {
        uint256 rewardId;
        uint256 fundId;
        uint256 totalNumber;
        uint256 actualNumber;
        address receiver;
        address nftAddress;
        uint256 nftId;
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
    }

    struct Reward {
        uint256 rewardId;
        address receiver;
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
    }

    Fund[] public funds;
    MicroFund[] public microFunds;
    Donate[] public donations;
    RewardPool[] public rewards;
    Reward[] public rewardList;

    constructor(address usdcAddress, address usdtAddress, address daiAddress) 
     {
        usdc = IERC20(usdcAddress);
        usdt = IERC20(usdtAddress);
        dai = IERC20(daiAddress);
    }

    /// @dev temporarily set only 1 level and fixed deadline, to make integration more simple
    /// @notice fund supports multicurrency deposits
    function createFund(
        uint256 _level1,
        address _rewardAddress,
        uint256 _rewardAmount
    ) public {
        /// @notice Create a new project to be funded
        /// @param _currency - token address, fund could be created in any token, this will be also required for payments // For now always 0
        /// @param _level1 - 1st (minimum) level of donation accomplishment, same works for all levels.
        /// @dev Frontend should handle parameters if no levels required. Level 1-5 have to be filled to max.
        uint256 _deadline = block.timestamp + 30 days; 
        require(msg.sender != address(0), "Invalid address");
        require(_level1 > 0, "Invalid amount");
        require(_level1 >= minAmount, "Value is lower than minimum possible amount");
        if (_rewardAmount > 0){
            require(_rewardAmount > _level1, "Reward amount should be higher than level 1");
            IERC20 rewardToken = IERC20(_rewardAddress);
            uint256 bal = rewardToken.balanceOf(msg.sender);
            require(_rewardAmount <= bal, "Not enough token in wallet");
            rewardToken.transferFrom(msg.sender, address(this), _rewardAmount);
        }
        // / @dev Only one active fund per address should be allowed (for now disabled)
        // for (uint256 i = 0; i < funds.length; i++) {
        //    require(funds[i].owner == msg.sender && funds[i].state == 0, "You already have a project");
        // }
        funds.push(
            Fund({
                owner: msg.sender,
                balance: 0,
                id: funds.length,
                state: 1,
                deadline: _deadline,
                level1: _level1,
                tokenReward: 0,
                tokenRewardAddress: _rewardAddress,
                usdcBalance: 0,
                usdtBalance: 0,
                daiBalance: 0
            })
        );
        emit FundCreated(
            msg.sender,
            _level1,
            funds.length
        );
    }

    function contribute(
        uint256 _amountM,
        uint256 _amountD,
        uint256 _id,
        uint256 _currency,
        bool _nftReward
    ) public isDeadlinePassed(_id) {
        /// @param _amountM - amount of tokens to be sent to microfund
        /// @param _amountD - amount of tokens to be direcly donated
        /// @notice User can create microfund and donate at the same time
        require(funds[_id].state == 1, "Fund is not active");
        require(msg.sender != address(0), "Invalid address");
        require(_amountM >= 0, "Invalid amount");
        require(_amountD >= 0, "Invalid amount");
        /// @notice Transfer function stores amount into this contract, both initial donation and microfund
        /// @dev User approval needed before the donation for _amount (FE part)
        /// @dev Currency recognition
        if (_currency == 1) {
            usdc.transferFrom(msg.sender, address(this), _amountD + _amountM);
            funds[_id].usdcBalance +=  _amountD + _amountM;
        } else if (_currency == 2)  {
            usdt.transferFrom(msg.sender, address(this), _amountD + _amountM);
            funds[_id].usdtBalance +=  _amountD + _amountM;
        } else if (_currency == 3){
            dai.transferFrom(msg.sender, address(this), _amountD + _amountM);
            funds[_id].daiBalance +=  _amountD + _amountM;
        } else {
            revert("Invalid currency");
        }
        funds[_id].balance += _amountD + _amountM;
        /// @notice If donated, fund adds balance and related microfunds are involed
        /// @notice Updated the direct donations
        if (_amountD > 0) {
            donations.push(
                Donate({
                    id: donations.length,
                    fundId: _id,
                    backer: msg.sender,
                    amount: _amountD,
                    state: 0,
                    currency: _currency /// TBD flexible in last stage
                })
            );
            emit Donated(msg.sender, _amountD, _id, _currency);
            drainMicro(_id, _amountD);
        }
        /// @notice If microfund created, it is added to the list
        if (_amountM > 0) {
            microFunds.push(
                MicroFund({
                    owner: msg.sender,
                    cap: _amountM,
                    microBalance: 0,
                    microId: microFunds.length,
                    fundId: _id,
                    state: 1,
                    currency: _currency
                })
            );
            emit MicroCreated(msg.sender, _amountM, _id, _currency);
        }
        if (_nftReward){
            rewardList.push(
                Reward({
                    rewardId: rewardList.length,
                    receiver: msg.sender,
                    state: 1
                })
            );
            /// Verify eligible number + Add actual number after the push RewardPool.[rewardID]
        }
    }

    function drainMicro(uint256 _id, uint256 _amount) internal {
        /// @notice Find all active microfunds related to the main fund and join the chain donation
        /// @notice Currency agnostic as all using stablecoin, if backer donates in DAI, microfund in USDC will join with USDC
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (
                microFunds[i].cap - microFunds[i].microBalance >= _amount &&
                microFunds[i].fundId == _id &&
                microFunds[i].state == 1
            ) {
                microFunds[i].microBalance += _amount;
                funds[_id].balance += _amount;
                if (microFunds[i].currency == 1){
                    funds[_id].usdcBalance += _amount;
                } else if (microFunds[i].currency == 2){
                    funds[_id].usdtBalance += _amount;
                } else if (microFunds[i].currency == 3){
                    funds[_id].daiBalance += _amount;
                }
                /// @notice Close microfund if it reaches its cap
                if (microFunds[i].cap == microFunds[i].microBalance) {
                    microFunds[i].state = 2;
                    emit MicroClosed(
                        microFunds[i].owner,
                        microFunds[i].cap,
                        microFunds[i].fundId
                    );
                }
                emit MicroDrained(microFunds[i].owner, _amount, _id); // TBD table
            }
        }
    }

    ///@notice Lock ERC1155 as crowdfunding reward - for example game items or NFT collectibles
    ///@notice One project could have multiple rewards
    /// TBD needed to distribute rewards after completion, return after cancellation
    function createNftReward(
        uint256 _fundId,
        uint256 _totalNumber,
        address _receiver,
        address _nftAddress,
        uint256 _nftId
    ) public {
        require(msg.sender != address(0), "Invalid address");
        require(_totalNumber > 0, "Invalid amount");
        IERC1155 rewardNft = IERC1155(_nftAddress);
        uint256 bal = rewardNft.balanceOf(msg.sender, _nftId);
        require(_totalNumber <= bal, "Not enough token in wallet");
        rewardNft.safeTransferFrom(msg.sender, address(this), _nftId, _totalNumber, "");
        /// TBD how to handle IDs, how to handle data
        rewards.push(
            RewardPool({
                rewardId: rewards.length,
                fundId: _fundId,
                totalNumber: _totalNumber,
                actualNumber: 0,
                receiver: _receiver,
                nftAddress: _nftAddress,
                nftId: _nftId,
                state: 1
            })
        );
    }


    function batchDistribute(IERC20 _rewardTokenAddress) public onlyOwner nonReentrant {
        for (uint256 i = 0; i < funds.length; i++) {
            /// @notice - Only active funds with achieved minimum are eligible for distribution
            /// @notice - Function for automation, checks deadline and handles distribution/cancellation
            if (block.timestamp < funds[i].deadline) {
                continue;
            }
            /// @notice - Fund accomplished minimum goal
            if (
                funds[i].state == 1 &&
                funds[i].balance >= funds[i].level1 &&
                block.timestamp > funds[i].deadline
            ) {
                distribute(i, _rewardTokenAddress);
            } 
            /// @notice - If not accomplished, funds are returned back to the users on home chain
            else if (
                funds[i].state == 1 &&
                funds[i].balance < funds[i].level1 &&
                block.timestamp > funds[i].deadline
            ) {
                cancelFund(i);
            }
        }
        // For each active fund check if cap is reached and if so
        // Call function "distributeRewards" pro každý font
    }

    /// @notice Distributes resources to the owner upon successful funding campaign
    /// @notice All related microfunds, and fund are closed
    /// @notice Check all supported currencies and distribute them to the project owner
    function distribute(uint256 _id, IERC20 _token) public nonReentrant {
        ///@dev TBD add requirements - deadline reached + amount reached...now left for testing purposes
        require(funds[_id].state == 1, "Fund is not active");
            if (funds[_id].usdcBalance > 0){
                distributeUni(_id, funds[_id].usdcBalance, 1, usdc);
            } 
            else if (funds[_id].usdtBalance > 0){
                distributeUni(_id, funds[_id].usdtBalance, 2, usdt);
            } 
            else if (funds[_id].daiBalance > 0){
                distributeUni(_id, funds[_id].daiBalance, 3, dai);
            } 
            if (funds[_id].balance > 0){
                funds[_id].balance = 0;
                emit IncorrectDistribution(true);
            }
            /// @dev Distribute an NFT to all backers
            for (uint256 i = 0; i < rewards.length; i++) {
                    if (rewards[i].fundId == _id && rewards[i].state == 0) {
                        for (uint256 j = 0; j < rewardList.length; j++) {
                            if (rewardList[j].rewardId == rewards[i].rewardId) {
                                IERC1155 rewardNft = IERC1155(rewards[i].nftAddress);
                                rewardNft.setApprovalForAll(rewardList[i].receiver, true);
                                rewardNft.safeTransferFrom(
                                    address(this),
                                    rewardList[j].receiver,
                                    rewards[i].nftId,
                                    1,
                                    ""
                                );
                            }
                        }
                    rewards[i].state = 1;
                    } 
            }
            /// @dev Distribute token reward if there is something locked
            if (funds[_id].tokenReward > 0){
                for (uint256 i = 0; i < donations.length; i++) {
                    if (donations[i].fundId == _id && donations[i].state == 0) {
                        uint256 proportion = (donations[i].amount * 100) / funds[_id].balance; // Underflow condition not covered
                        uint256 share = (proportion) * (funds[_id].tokenReward / funds[_id].balance);
                        ///@notice refund the backers of the EYE token
                            _token.approve(donations[i].backer, funds[_id].tokenReward);
                            _token.transferFrom(
                                address(this),
                                donations[i].backer,
                                share
                            );
                            donations[i].state = 2;
                            emit TokenReward(
                                donations[i].backer,
                                donations[i].amount,
                                _id
                            );
                        } 
                }
            }

            /// @dev TBD State should be ideally handled inside the universal function, so higher level functions could be extracted elsewhere
            funds[_id].usdcBalance = 0; ///@dev closing the fund
            funds[_id].usdtBalance = 0; 
            funds[_id].daiBalance = 0; 
            funds[_id].state = 2;
    }  

    function distributeUni(uint256 _id, uint256 _fundBalance, uint256 _currency, IERC20 _token) internal {
            _token.approve(address(this), _fundBalance);
             /// @notice Take 1% fee to Eyeseek treasury
            uint256 fee = (_fundBalance * 1) / 100;
            uint256 gain = _fundBalance - fee;
            _token.transferFrom(address(this), feeAddress, fee);
            emit PlatformFee(funds[_id].owner, fee);
            _token.transferFrom(address(this), funds[_id].owner, gain);
            emit DistributionAccomplished(funds[_id].owner, _fundBalance, _currency);
            funds[_id].balance -= _fundBalance;
            /// @notice Resources are returned back to the microfunds
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == _currency) {
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        uint256 diff = microFunds[i].cap - microFunds[i].microBalance;
                        _token.approve(address(this), diff);
                        _token.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            diff
                        );
                        emit Returned(
                            microFunds[i].owner,
                            diff,
                            funds[_id].owner
                        );
                    }
                    microFunds[_id].microBalance = 0; ///@dev resets the microfund
                    microFunds[i].state = 2; ///@dev closing the microfunds
                }
            }
    }

    
    ///@notice - Checks balances for each supported currency and returns funds back to the users
    ///@dev 0=Cancelled, 1=Active, 2=Finished
    ///@dev TBD - Return locked reward to the owner
    function cancelFund(uint256 _id) public nonReentrant {
        require(funds[_id].state == 1, "Fund is not active");
        if (
            msg.sender == funds[_id].owner || msg.sender == address(this)
        ) {
            if (funds[_id].usdcBalance > 0){
                cancelUni(_id, funds[_id].usdcBalance, 1, usdc);
            }
            if (funds[_id].usdtBalance > 0){
                cancelUni(_id, funds[_id].usdtBalance, 2, usdt);
            }
            if (funds[_id].daiBalance > 0){
                cancelUni(_id, funds[_id].daiBalance, 3, dai);
            }          
          }
            /// @notice - Ideally project fund should be empty and can be closed
            if (funds[_id].balance == 0) {
                funds[_id].state = 2;
                emit Cancelled(funds[_id].owner, funds[_id].id);
            } else {
                emit IncorrectDistribution(true);
            }
          ///@dev closing the fund
            funds[_id].usdtBalance = 0; 
            funds[_id].daiBalance = 0; 
            funds[_id].state = 0; ///@notice 0=Cancelled, 1=Active, 2=Finished
         }
        

    ///@notice - Cancel the fund and return the resources to the microfunds, universal for all supported currencies
    function cancelUni(uint256 _id, uint256 _fundBalance, uint256 _currency, IERC20 _token ) internal {
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == _currency) {
                    /// @notice Send back the remaining amount to the microfund owner
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        _token.approve(address(this), microFunds[i].cap);
                        _token.transferFrom(
                            address(this),
                            microFunds[i].owner,
                            microFunds[i].cap
                        );
                        
                        emit Returned(
                            microFunds[i].owner,
                            microFunds[i].cap,
                            funds[i].owner
                        );
                    }
                    funds[_id].balance -= microFunds[i].cap;
                    microFunds[i].state = 4;
                    _fundBalance -= microFunds[i].cap;
                }
            }
        
            ///@dev Fund states - 0=Created, 1=Distributed, 2=Refunded
            for (uint256 i = 0; i < donations.length; i++) {
                if (donations[i].fundId == _id && donations[i].state == 0 && donations[i].currency == _currency) {
                        _token.approve(address(this), donations[i].amount);
                        _token.transferFrom(
                            address(this),
                            donations[i].backer,
                            donations[i].amount
                        );
                        funds[_id].balance -= donations[i].amount;
                        _fundBalance -= donations[i].amount;
                        donations[i].state = 4;
                        emit Refunded(
                            donations[i].backer,
                            donations[i].amount,
                            _id
                        );
                }
              }
           }

    
    // ------ ADMIN FUNCTIONS ----------
    /// @notice Allow admin to change minimum amount for new projects
    /// @param _min - Minimum amount to create fund with
    function setMinimum(uint256 _min) public onlyOwner {
        minAmount = _min;
    }

    /// @notice Ability to change platform fee without need for contract redeployment
    function changeFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
    }

    // ------ VIEW FUNCTIONS ----------

    /// @notice - Get total number of microfunds connected to the ID of fund
    /// @param _index - ID of the fund
    function getConnectedMicroFunds(uint256 _index)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (microFunds[i].fundId == _index) {
                count++;
            }
        }
        return count;
    }

    /// @notice - Calculate amounts of all involved microfunds in the donation
    /// @param _index - ID of the fund
    /// @param _amount - Amount of the donation
    function calcOutcome(uint256 _index, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        total += _amount;
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (
                microFunds[i].fundId == _index &&
                microFunds[i].state == 1 &&
                microFunds[i].cap - microFunds[i].microBalance >= _amount
            ) {
                total += _amount;
            }
        }
        return total;
    }

    /// @notice - Calculate number of involved microfunds for specific donation amount
    /// @param _index - ID of the fund
    /// @param _amount - Amount of the donation
    function calcInvolvedMicros(uint256 _index, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 microNumber = 0;
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (
                microFunds[i].fundId == _index &&
                microFunds[i].state == 1 &&
                microFunds[i].cap - microFunds[i].microBalance >= _amount
            ) {
                microNumber++;
            }
        }
        return microNumber;
    }

    /// @notice - Calculate number of involved microfunds for specific donation amount
    /// @param _index - ID of the fund
    function getBackers(uint256 _index)
        public
        view
        returns (uint256)
    {
        uint256 backerNumber = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (
                donations[i].fundId == _index
            ) {
                backerNumber++;
            }
        }
        return backerNumber;
    }


    event FundCreated(address owner, uint256 cap, uint256 id);
    event MicroCreated(address owner, uint256 cap, uint256 fundId, uint256 currency);
    event Donated(address donator, uint256 amount, uint256 fundId, uint256 currency);
    event MicroDrained(address owner, uint256 amount, uint256 fundId);
    event MicroClosed(address owner, uint256 cap, uint256 fundId);
    event DistributionAccomplished(address owner, uint256 balance, uint256 currency);
    event Refunded(address backer, uint256 amount, uint256 fundId);
    event TokenReward(address backer, uint256 amount, uint256 fundId);
    event Returned(address microOwner, uint256 balance, address fundOwner);
    event FundingFee(address project, uint256 fee);
    event PlatformFee(address project, uint256 fee);
    event Cancelled(address owner, uint256 fundId);
    event IncorrectDistribution(bool status);
}

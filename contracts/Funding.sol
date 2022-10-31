// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";

/// @title Chain donation contract
/// @author Michal Kazdan

/// import "hardhat/console.sol";

contract Funding is Ownable, ReentrancyGuard, AxelarExecutable {
    IERC20 public usdc;
    IERC20 public usdt;
    IERC20 public dai;
    IERC20 public rewardToken;
    /// TBD  axlUSDC to add if implementation would be successful
    /// TBD new events to watch - negative scenarios - error log
    /// TBD for each currency needed to separate general functions, ideally create a library


    address public feeAddress = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    uint256 public minAmount = 1;
    uint256 public platformFee = 1;

    /// @dev Axelar - Lets start with hard Polygon gateway
    /// @dev In case of spreading core cotnract into multiple blockchain, put gateway address in constructor
    //address public gateway = 0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B; 
    IAxelarGasService immutable gasReceiver = IAxelarGasService(0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6);
   

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


    Fund[] public funds;
    MicroFund[] public microFunds;
    Donate[] public donations;

    constructor(address _gateway, address usdcAddress, address usdtAddress, address daiAddress) 
         AxelarExecutable(_gateway)
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
            rewardToken = IERC20(_rewardAddress); 
            uint256 bal = rewardToken.balanceOf(msg.sender);
            require(_rewardAmount <= bal, "Not enough token in wallet");
            rewardToken.transferFrom(msg.sender, address(this), _rewardAmount);
        }
        /// @dev Only one active fund per address should be allowed (for now disabled)
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
        uint256 _currency
    ) public isDeadlinePassed(_id) {
        /// @param _amountM - amount of tokens to be sent to microfund
        /// @param _amountD - amount of tokens to be direcly donated
        /// @notice User can create microfund and donate at the same time
        /// @notice If he donates
        require(msg.sender != address(0), "Invalid address");
        require(_amountM >= 0, "Invalid amount");
        require(_amountD >= 0, "Invalid amount");
        require(funds[_id].state == 1, "Fund is not active");
        /// @notice Transfer function stores amount into this contract, both initial donation and microfund
        /// @dev User approval needed before the donation for _amount (FE part)
        /// @dev Currency recognition
        if (_currency == 1) {
            usdc.transferFrom(msg.sender, address(this), _amountD + _amountM);
        } else if (_currency == 2)  {
            usdt.transferFrom(msg.sender, address(this), _amountD + _amountM);
        } else if (_currency == 3){
            dai.transferFrom(msg.sender, address(this), _amountD + _amountM);
        } else {
        revert("Invalid currency");
        }
        /// @notice If donated, fund adds balance and related microfunds are involed
        ///@dev 0=Donated, 1=Distributed, 2=Refunded
        if (_amountD > 0) {
            funds[_id].balance += _amountD;
                if (_currency == 1) {
                    funds[_id].usdcBalance += _amountD;
                } else if (_currency == 2)  {
                    funds[_id].usdtBalance += _amountD;
                } else if (_currency == 3){
                    funds[_id].daiBalance += _amountD;
                } 
            // Updated the direct donations
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

    function batchDistribute() public onlyOwner nonReentrant {
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
                distribute(i);
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
    /// @notice Only admin can distribute rewards
    /// @notice All microfunds, and fund are closed
    /// @notice Check all supported currencies and distribute them to the project owner
    function distribute(uint256 _id) public nonReentrant {
        /// TBD add requirements - deadline + funds accomplished...now left for testing purposes
        /// TBD add onlyOwner before MVP
        require(funds[_id].state == 1, "Fund is not active");
        if (funds[_id].usdcBalance > 0){
            usdc.approve(address(this), funds[_id].usdcBalance);
             /// @notice Take 1% fee to Eyeseek treasury
            uint256 usdcFee = (funds[_id].usdcBalance * 1) / 100;
            uint256 usdcGain = funds[_id].usdcBalance - usdcFee;
            usdc.transferFrom(address(this), feeAddress, usdcFee);
            emit UsdcFee(funds[_id].owner, usdcFee);
            usdc.transferFrom(address(this), funds[_id].owner, usdcGain);
            emit UsdcDistributed(funds[_id].owner, funds[_id].usdcBalance);
            funds[_id].balance -= funds[_id].usdcBalance;
            /// @notice Resources are returned back to the microfunds
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == 1) {
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        uint256 usdcDifference = microFunds[i].cap - microFunds[i].microBalance;
                        usdc.approve(address(this), usdcDifference);
                        usdc.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            usdcDifference
                        );
                        emit Returned(
                            microFunds[i].owner,
                            usdcDifference,
                            funds[_id].owner
                        );
                    }
                    microFunds[_id].microBalance = 0; ///@dev resets the microfund
                    microFunds[i].state = 2; ///@dev closing the microfunds
                }
            }
        } 
        // else if (funds[_id].usdtBalance > 0){
        //     usdt.approve(address(this), funds[_id].usdtBalance);
        //      /// @notice Take 1% fee to Eyeseek treasury
        //     uint256 usdtFee = (funds[_id].usdtBalance * 1) / 100;
        //     uint256 usdtGain = funds[_id].usdtBalance - usdtFee;
        //     usdt.transferFrom(address(this), feeAddress, usdtFee);
        //     emit UsdtFee(funds[_id].owner, usdtFee);
        //     usdt.transferFrom(address(this), funds[_id].owner, usdtGain);
        //     emit UsdtDistributed(funds[_id].owner, funds[_id].usdtBalance);
        //     funds[_id].balance -= funds[_id].usdtBalance;
        //     /// @notice Resources are returned back to the microfunds
        //     for (uint256 i = 0; i < microFunds.length; i++) {
        //         if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == 2) {
        //             if (microFunds[i].cap > microFunds[i].microBalance) {
        //                 uint256 usdtDifference = microFunds[i].cap - microFunds[i].microBalance;
        //                 usdt.approve(address(this), usdtDifference);
        //                 usdt.transferFrom(
        //                     address(this),
        //                     microFunds[_id].owner,
        //                     usdtDifference
        //                 );
        //                 emit Returned(
        //                     microFunds[i].owner,
        //                     usdtDifference,
        //                     funds[_id].owner
        //                 );
        //             }
        //             microFunds[_id].microBalance = 0; ///@dev resets the microfund
        //             microFunds[i].state = 2; ///@dev closing the microfunds
        //         }
        //     }
        // } 
        // else if (funds[_id].daiBalance > 0){
        //     dai.approve(address(this), funds[_id].daiBalance);
        //      /// @notice Take 1% fee to Eyeseek treasury
        //     uint256 daiFee = (funds[_id].daiBalance * 1) / 100;
        //     uint256 daiGain = funds[_id].daiBalance - daiFee;
        //     dai.transferFrom(address(this), feeAddress, daiFee);
        //     emit DaiFee(funds[_id].owner, daiFee);
        //     dai.transferFrom(address(this), funds[_id].owner, daiGain);
        //     emit UsdtDistributed(funds[_id].owner, funds[_id].daiBalance);
        //     funds[_id].balance -= funds[_id].daiBalance;
        //     /// @notice Resources are returned back to the microfunds
        //     for (uint256 i = 0; i < microFunds.length; i++) {
        //         if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == 3) {
        //             if (microFunds[i].cap > microFunds[i].microBalance) {
        //                 uint256 daiDifference = microFunds[i].cap - microFunds[i].microBalance;
        //                 dai.approve(address(this), daiDifference);
        //                 dai.transferFrom(
        //                     address(this),
        //                     microFunds[_id].owner,
        //                     daiDifference
        //                 );
        //                 emit Returned(
        //                     microFunds[i].owner,
        //                     daiDifference,
        //                     funds[_id].owner
        //                 );
        //             }
        //             microFunds[_id].microBalance = 0; ///@dev resets the microfund
        //             microFunds[i].state = 2; ///@dev closing the microfunds
        //         }
        //     }
        // } 
            if (funds[_id].balance > 0){
                funds[_id].balance = 0;
                emit IncorrectDistribution(true);
            }
    
            funds[_id].state = 2;
    }  

    ///@dev 0=Cancelled, 1=Active, 2=Finished
    /// TBD currency condition
    function cancelFund(uint256 _id) public nonReentrant {
        require(funds[_id].state == 1, "Fund is not active");
        require(
            usdc.balanceOf(address(this)) >= funds[_id].balance,
            "Not enough tokens in the contract"
        );
        if (
            msg.sender == funds[_id].owner || msg.sender == address(this)
        ) {
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1) {
                    /// @notice Close microfund
                    /// @notice Optional piece of code - Send back the remaining amount to the microfund owner
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        usdc.approve(address(this), microFunds[i].cap);
                        usdc.transferFrom(
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
                    microFunds[i].state = 2;
                }
            }
        
            ///@dev Fund states - 0=Donated, 1=Distributed, 2=Refunded
            for (uint256 i = 0; i < donations.length; i++) {
                if (donations[i].fundId == _id && donations[i].state == 0) {
                    ///@notice refund the backers of the EYE token
                    /// TBD refund all 4 currencies 
                        usdc.approve(address(this), donations[i].amount);
                        usdc.transferFrom(
                            address(this),
                            donations[i].backer,
                            donations[i].amount
                        );
                        funds[_id].balance -= donations[i].amount;
                        donations[i].state = 2;
                        emit Refunded(
                            donations[i].backer,
                            donations[i].amount,
                            _id
                        );
                }
            }
    
            /// @notice - Ideally project fund should be empty and can be closed
            if (funds[_id].balance == 0) {
                funds[_id].state = 2;
                emit Cancelled(funds[_id].owner, funds[_id].id);
            } else {
                emit IncorrectDistribution(true);
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

    /// @notice Indicates penalty-free withdrawal period
    function isPeriodFinished(uint256 _index) public view returns (bool) {
        return block.timestamp > funds[_index].deadline;
    }

    /// @notice - Get project deadline
    function getFundDeadline(uint256 _index) public view returns (uint256) {
        return funds[_index].deadline;
    }

    /// @notice - Get project minimal cap
    function getFundCap(uint256 _index) public view returns (uint256) {
        return funds[_index].level1;
    }

    /// @notice - Get project actual backing
    function getFundBalance(uint256 _index) public view returns (uint256) {
        return funds[_index].balance;
    }

    /// @notice - Get detail about a microfund
    function getMicroFundInfo(uint256 _index)
        public
        view
        returns (
            uint256 state,
            uint256 max,
            uint256 balance,
            uint256 currency
        )
    {
        MicroFund storage microFund = microFunds[_index];
        return (microFund.state, microFund.microBalance, microFund.cap, microFund.currency);
    }

    ///@dev Experimental with Axelar
    function _executeWithToken(
        string memory,
        string memory,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount 
    ) internal override nonReentrant {
        // get ERC-20 address from gateway
        address recipient = abi.decode(payload, (address));
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);
        IERC20(tokenAddress).transfer(recipient, amount);
        emit AxelarExecutionComplete(amount, tokenSymbol);
    }

    

    event AxelarExecutionComplete(uint256 amount, string symbol);
    event FundCreated(address owner, uint256 cap, uint256 id);
    event MicroCreated(address owner, uint256 cap, uint256 fundId, uint256 currency);
    event Donated(address donator, uint256 amount, uint256 fundId, uint256 currency);
    event MicroDrained(address owner, uint256 amount, uint256 fundId);
    event MicroClosed(address owner, uint256 cap, uint256 fundId);
    event Distributed(address owner, uint256 balance);
    event UsdcDistributed(address owner, uint256 balance);
    event DaiDistributed(address owner, uint256 balance);
    event UsdtDistributed(address owner, uint256 balance);
    event Refunded(address backer, uint256 amount, uint256 fundId);
    event Returned(address microOwner, uint256 balance, address fundOwner);
    event FundingFee(address project, uint256 fee);
    event UsdcFee(address project, uint256 fee);
    event UsdtFee(address project, uint256 fee);
    event DaiFee(address project, uint256 fee);
    event Cancelled(address owner, uint256 fundId);
    event IncorrectDistribution(bool status);
}

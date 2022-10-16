// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/// @title Chain donation contract
/// @author Michal Kazdan

/// TBD tasky, 
// Get historical donation data for users/funds 
// View funkce spravit - Neukazují dobře, doplnit testy
import "hardhat/console.sol";

contract Donator is Ownable, ReentrancyGuard  {

    IERC20 public token;
    IERC20 public usdc;

    address public feeAddress = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;


    /// @notice Main crowdfunding fund 
    struct Fund {
        uint256 id;
        address owner;
        uint256 max;
        uint256 balance;
        uint256 state;  ///@dev 0=Cancelled, 1=Active, 2=Finished
        uint256 currency; /// 0-5 
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
    }

    /// @notice Unlimited amount of microfunds could be connect with a main fund
    struct MicroFund {
        uint256 microId;
        address owner;
        uint256 cap;
        uint256 microBalance;
        uint256 fundId;
        uint256 state;///@dev 0=Cancelled, 1=Active, 2=Finished
    }

    Fund[] public funds;
    MicroFund[] public microFunds;


    /// @notice Custom token for value exchange in the project
    constructor(address tokenAddress, address usdcAddress) {
        token = IERC20(tokenAddress);
        usdc = IERC20(usdcAddress);
    }


    function createFund(uint256 _amount, uint256 _currency, uint256 _level1, uint256 _level2, uint256 _level3, uint256 _level4, uint256 _level5) public {
            /// @param _amount - funding limit to be achievable
            /// @param _currency - token address, fund could be created in any token, this will be also required for payments
            /// @param _level1 - 1st level of donation accomplishment, same works for all levels. 
            /// @dev Frontend should handle parameters if no levels required. Level 1-5 have to be filled to max.
            require(msg.sender != address(0), "Invalid address");
            require(_amount > 0, "Invalid amount");
            require(_max >= _level5, "Level 5 cannot exceed fund cap");
        //    require(Fund.balance < Fund.max, "Fund is full");
            funds.push(Fund({owner: msg.sender, max: _amount, balance: 0, id: funds.length, state: 1, currency: _currency, level1: _level1, level2: _level2, level3: _level3, level4: _level4, level5: _level5}));
            emit FundCreated(msg.sender, _amount, funds.length, currency);
    }

    function createMicroFund(uint256 _amountM, uint256 _amountD, uint256 _id) public {
            require(msg.sender != address(0), "Invalid address");
            require(_amountM >= 0, "Invalid amount");
            require(_amountD >= 0, "Invalid amount");
            require(funds[_id].state == 1, "Fund is not active");
            /// @notice Transfer function stores amount into this contract, both initial donation and microfund
            /// @dev User approval needed before the donation for _amount (FE part)

            /// @dev Currency recognition
            /// @notice Ideally set up to 5 currencies for each deployed chain (Native, Stablecoin1, Stablecoin2, EyeToken)
            if (funds[_id].currency == 0) {
                token.transferFrom(msg.sender, address(this), _amountD + _amountM);
            } else if (funds[_id].currency == 1) {
                usdc.transferFrom(msg.sender, address(this), _amountD + _amountM);
            } else {
                revert("Invalid currency");
            }
            drainMicro(_id, _amountD);
            microFunds.push(MicroFund({owner: msg.sender, cap: _amountM, microBalance: 0, microId: microFunds.length, fundId: _id, state: 1 }));
            emit MicroFundCreated(msg.sender, _amountM, _id);
    }

    function drainMicro(uint256 _id, uint256 _amount) internal {
            /// @notice Second call microfunds to join
            /// @notice Find all active microfunds related to the main fund and join the chain donation
            for (uint i=0; i<microFunds.length; i++) {
                    if (microFunds[i].cap - microFunds[i].microBalance >= _amount && microFunds[i].fundId == _id &&  microFunds[i].state == 1) {
                        microFunds[i].microBalance += _amount;
                        funds[_id].balance += _amount;
            
                        /// @notice Close microfund if it reaches its cap
                        if (microFunds[i].cap == microFunds[i].microBalance) {
                            microFunds[i].state = 2; 
                            emit MicroClosed(microFunds[i].owner, microFunds[i].cap, microFunds[i].fundId);
                        }
                        emit MicroDonated(microFunds[i].owner, _amount, _id);
                    }
            }
   }

    function donate(uint256 _amount, uint256 _id) public nonReentrant {
            require(msg.sender != address(0), "Invalid address");
            require(_amount > 0, "Invalid amount");
            require(funds[_id].state == 1, "Fund is not active");
            /// @notice Contract assurance donation would not exceed capacity
            /// @dev Frontend control is preferred in this situation for better UX using calcOutcome()
            uint256 outcome;
            outcome = calcOutcome(_id, _amount);
            require(outcome <= funds[_id].max, "Funding amount exceeds capacity");

            /// @notice First require transfer directly from donator
            /// @dev User approval needed before the donation for _amount (FE part)
            token.transferFrom(msg.sender, address(this), _amount);
            funds[_id].balance += _amount;

            /// @notice Second call microfunds to join
            /// @notice Find all active microfunds related to the main fund and join the chain donation
            drainMicro(_id, _amount);
            emit Donated(msg.sender, _amount, _id);
        }

    function batchDistribute () public {
        // For each active fund check if cap is reached and if so
        // Call function "distributeRewards" pro každý font  
    }
    
    /// @notice Only admin can distribute rewards
    /// @notice All microfunds, and fund are closed
    /// @dev - Both functions could be merged into one
    /// @dev - TBD - Spojit distribute funkci do jednoho
    function distributeRewards(uint256 _id) public onlyOwner nonReentrant{
        require(funds[_id].state == 1, "Fund is not active");
        require(usdc.balanceOf(address(this)) >= funds[_id].balance, "Not enough tokens in the contract");
        usdc.approve(address(this), funds[_id].balance);
       

        /// @notice Optional three following rows to setup fee upon successful funding
        uint256 fee = funds[_id].balance * 1 / 100;
        uint256 fundGain = funds[_id].balance - fee;
        usdc.transferFrom(address(this), feeAddress, fee);
        emit FundingFee(funds[_id].owner, fee);
        
        /// @notice Distribute rewards to fund owner
        usdc.transferFrom(address(this), funds[_id].owner, fundGain);
        funds[_id].state = 2;
        for (uint i=0; i<microFunds.length; i++) {
             if (microFunds[i].fundId == _id &&  microFunds[i].state == 1) {
        /// @notice Close microfund
        /// @notice Optional piece of code - Send back the remaining amount to the microfund owner
            if (microFunds[i].cap > microFunds[i].microBalance) {
                uint256 difference = microFunds[i].cap - microFunds[i].microBalance;
                usdc.approve(address(this), difference);
                usdc.transferFrom(address(this), microFunds[_id].owner,difference);
                console.log("Contract still has %s", usdc.balanceOf(address(this)), i);
                emit Returned(microFunds[i].owner, difference, funds[_id].owner);
            }
            microFunds[i].state = 2; 
      }
      }
        emit Distributed(funds[_id].owner, funds[_id].balance);
    }

    /// @notice Only admin can distribute rewards
    /// @notice All microfunds, and fund are closed
    function distributeEye(uint256 _id) public onlyOwner nonReentrant{
        require(funds[_id].state == 1, "Fund is not active");
        require(token.balanceOf(address(this)) >= funds[_id].balance, "Not enough tokens in the contract");
        token.approve(address(this), funds[_id].balance);

        /// @notice Distribute rewards to fund owner
        token.transferFrom(address(this), funds[_id].owner, funds[_id].balance);
        funds[_id].state = 2;
        for (uint i=0; i<microFunds.length; i++) {
             if (microFunds[i].fundId == _id &&  microFunds[i].state == 1) {
        /// @notice Close microfund
        /// @notice Optional piece of code - Send back the remaining amount to the microfund owner
            if (microFunds[i].cap > microFunds[i].microBalance) {
                uint256 difference = microFunds[i].cap - microFunds[i].microBalance;
                token.approve(address(this), difference);
                token.transferFrom(address(this), microFunds[_id].owner,difference);
                console.log("Contract still has %s", token.balanceOf(address(this)), i);
                emit Returned(microFunds[i].owner, difference, funds[_id].owner);
            }
            microFunds[i].state = 2; 
      }
      }
        emit Distributed(funds[_id].owner, funds[_id].balance);
    }

    function cancelMicrofund(uint256 _id) public onlyOwner nonReentrant{
        require(funds[_id].state == 1, "Fund is not active");
        require(token.balanceOf(address(this)) >= funds[_id].balance, "Not enough tokens in the contract");

       
        for (uint i=0; i<microFunds.length; i++) {
             if (microFunds[i].fundId == _id &&  microFunds[i].state == 1) {
        /// @notice Close microfund
        /// @notice Optional piece of code - Send back the remaining amount to the microfund owner
            if (microFunds[i].cap > microFunds[i].microBalance) {
                token.approve(address(this), microFunds[_id].cap);
                token.transferFrom(address(this), microFunds[_id].owner, microFunds[_id].cap);
                console.log("Contract still has %s", token.balanceOf(address(this)), i);
                emit Returned(microFunds[i].owner, microFunds[_id].cap, funds[_id].owner);
            }
            microFunds[i].state = 2; 
            }
         }
         funds[_id].state = 2;
    }

        // ------ VIEW FUNCTIONS ---------- 
        function getFundInfo(uint _index) public view returns (uint256 state, uint256 max, uint256 balance) {
            Fund storage fund = funds[_index];
            return (fund.state, fund.max, fund.balance);
        }

        // Get number of microfunds
        function getConnectedMicroFunds(uint _index) public view returns (uint256) {
            uint256 count = 0;
            for (uint i=0; i<microFunds.length; i++) {
                if (microFunds[i].fundId == _index) {
                    count++;
                }
            }
            return count;
        }

        function calcOutcome(uint _index, uint256 _amount) public view returns (uint256) {
            uint256 total = 0;
            total += _amount;
            for (uint i=0; i<microFunds.length; i++) {
                if (microFunds[i].fundId == _index && microFunds[i].state == 1 && microFunds[i].cap - microFunds[i].microBalance >= _amount) {
                    total += _amount;
                }
            }
            return total;
        }

        
        function calcInvolvedMicros(uint _index, uint256 _amount) public view returns (uint256) {
            uint256 microNumber = 0;
            for (uint i=0; i<microFunds.length; i++) {
                if (microFunds[i].fundId == _index && microFunds[i].state == 1 && microFunds[i].cap - microFunds[i].microBalance >= _amount) {
                    microNumber ++;
                }
            }
            return microNumber;
        }

        /// Get donation history
        /// @dev Same function will be backed by centralized backend for start
        function getDonationHistory(address _address) public view returns (uint256[] memory) {
            /// @param _address - address of the donator
            /// Get all historical donations - to specific project
            /// Get all historical microfunds - to specific project 
        }


        function getMicroFundInfo(uint _index) public view returns (uint256 state, uint256 max, uint256 balance) {
            MicroFund storage microFund = microFunds[_index];
            return (microFund.state, microFund.microBalance, microFund.cap);
        }



    event FundCreated(address owner, uint256 cap, uint256 id);
    event MicroFundCreated(address owner, uint256 cap, uint256 fundId);
    event Donated(address donator, uint256 amount, uint256 fundId);
    event MicroDonated(address owner, uint256 amount, uint256 fundId);
    event MicroClosed(address owner, uint256 cap, uint256 fundId);
    event Distributed(address owner, uint256 balance);
    event Returned(address microOwner, uint256 balance, address fundOwner);
    event FundingFee(address project, uint256 fee);
}

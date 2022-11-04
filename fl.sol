// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.7.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.7.3


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.7.3


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.7.3


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/Funding.sol


pragma solidity ^0.8.9;
/// @title Chain donation contract
/// @author Michal Kazdan

/// import "hardhat/console.sol";

contract Funding is Ownable, ReentrancyGuard {
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
            rewardToken = IERC20(_rewardAddress); 
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

    // function batchDistribute() public onlyOwner nonReentrant {
    //     for (uint256 i = 0; i < funds.length; i++) {
    //         /// @notice - Only active funds with achieved minimum are eligible for distribution
    //         /// @notice - Function for automation, checks deadline and handles distribution/cancellation
    //         if (block.timestamp < funds[i].deadline) {
    //             continue;
    //         }
    //         /// @notice - Fund accomplished minimum goal
    //         if (
    //             funds[i].state == 1 &&
    //             funds[i].balance >= funds[i].level1 &&
    //             block.timestamp > funds[i].deadline
    //         ) {
    //             distribute(i);
    //         } 
    //         /// @notice - If not accomplished, funds are returned back to the users on home chain
    //         else if (
    //             funds[i].state == 1 &&
    //             funds[i].balance < funds[i].level1 &&
    //             block.timestamp > funds[i].deadline
    //         ) {
    //             cancelFund(i);
    //         }
    //     }
    //     // For each active fund check if cap is reached and if so
    //     // Call function "distributeRewards" pro ka┼żd├Ż font
    // }
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
        else if (funds[_id].usdtBalance > 0){
            usdt.approve(address(this), funds[_id].usdtBalance);
             /// @notice Take 1% fee to Eyeseek treasury
            uint256 usdtFee = (funds[_id].usdtBalance * 1) / 100;
            uint256 usdtGain = funds[_id].usdtBalance - usdtFee;
            usdt.transferFrom(address(this), feeAddress, usdtFee);
            emit UsdtFee(funds[_id].owner, usdtFee);
            usdt.transferFrom(address(this), funds[_id].owner, usdtGain);
            emit UsdtDistributed(funds[_id].owner, funds[_id].usdtBalance);
            funds[_id].balance -= funds[_id].usdtBalance;
            /// @notice Resources are returned back to the microfunds
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == 2) {
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        uint256 usdtDifference = microFunds[i].cap - microFunds[i].microBalance;
                        usdt.approve(address(this), usdtDifference);
                        usdt.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            usdtDifference
                        );
                        emit Returned(
                            microFunds[i].owner,
                            usdtDifference,
                            funds[_id].owner
                        );
                    }
                    microFunds[_id].microBalance = 0; ///@dev resets the microfund
                    microFunds[i].state = 2; ///@dev closing the microfunds
                }
            }
        } 
        else if (funds[_id].daiBalance > 0){
            dai.approve(address(this), funds[_id].daiBalance);
             /// @notice Take 1% fee to Eyeseek treasury
            uint256 daiFee = (funds[_id].daiBalance * 1) / 100;
            uint256 daiGain = funds[_id].daiBalance - daiFee;
            dai.transferFrom(address(this), feeAddress, daiFee);
            emit DaiFee(funds[_id].owner, daiFee);
            dai.transferFrom(address(this), funds[_id].owner, daiGain);
            emit UsdtDistributed(funds[_id].owner, funds[_id].daiBalance);
            funds[_id].balance -= funds[_id].daiBalance;
            /// @notice Resources are returned back to the microfunds
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1 && microFunds[i].currency == 3) {
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        uint256 daiDifference = microFunds[i].cap - microFunds[i].microBalance;
                        dai.approve(address(this), daiDifference);
                        dai.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            daiDifference
                        );
                        emit Returned(
                            microFunds[i].owner,
                            daiDifference,
                            funds[_id].owner
                        );
                    }
                    microFunds[_id].microBalance = 0; ///@dev resets the microfund
                    microFunds[i].state = 2; ///@dev closing the microfunds
                }
            }
        } 
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
    function getFundDeadline (uint256 _index) public view returns (uint256) {
        if (funds[_index].deadline > block.timestamp) {
            return funds[_index].deadline - block.timestamp;
        } else {
            return 0;
        }
    }

    /// @notice - Get project minimal cap
    function getFundCap(uint256 _index) public view returns (uint256) {
        return funds[_index].level1;
    }

    /// @notice - Get project actual backing
    function getFundBalance(uint256 _index) public view returns (uint256) {
        return funds[_index].balance;
    }

    /// @notice - Get balances across all currencies
    function getAllBalances(uint256 _index) public view returns (uint256, uint256, uint256, uint256) {
        return (funds[_index].balance, funds[_index].usdcBalance, funds[_index].usdtBalance, funds[_index].daiBalance);
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

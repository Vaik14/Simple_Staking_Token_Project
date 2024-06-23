//  SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract TokenStaking {
    ///////////////////
    // Errors
    ///////////////////
    error TokenStaking_NotOwner();
    error TokenStaking_NoRecordFound();
    error TokenStaking_NotEnoughTokens();
    error TokenStaking_Not_A_Token_Holder();
    
    ///////////////////
    // State Variables
    ///////////////////
    address public s_owner;
    IERC20 public token;
    uint256 public i_deployedAt;

    uint256 public constant s_annualRewardPercentage =360;          // s_annualRewardPercentage is 36%
    uint256 public constant DENOMINATOR = 1000;               
    uint256 public constant s_minimumStakingValue = 1 ether;        // user needs to stake atleast 1 TOKEN token
    uint256 public s_totalStakedTokens;
    uint256 public s_totalRewardsGiven;

    ///////////////////
    // Types
    ///////////////////
   struct StakingDetails {
        uint256 startTime;
        uint256 endTime;
        uint256 stakedAmount;
        uint256 claimableRewards;
        uint256 lastRewardClaimedAt;
        uint256 totalRewardsClaimed;
    }

    ///////////////////
    // Mappings
    ///////////////////
    mapping(address => StakingDetails) public AddressToStakingDetails;
    
    ///////////////////
    // Events
    ///////////////////
    event staked(address indexed userAddress,uint256 stakedAt,uint256 stakedValue);
    event unStaked(address indexed userAddress, uint256 endTime);
    event claimReward(address indexed userAddress,uint256 time,uint256 rewards);

    ///////////////////
    // Modifiers
    ///////////////////
    modifier onlyOwner() {
        if (msg.sender != s_owner) revert TokenStaking_NotOwner();
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(address i_tokenAddress) {
        token = IERC20(i_tokenAddress);
        i_deployedAt = block.timestamp;
        s_owner = msg.sender;
    }

 
    /**
     * @param amount is the amount the user want to stake
    */
    function stakeTokens(uint256 amount) external returns(bool){
        uint256 balance = token.balanceOf(msg.sender);
        require(amount >= s_minimumStakingValue,"Value is less than minimum value required to stake");
        require(balance >= amount, "You don't have enough tokens to stake");
        StakingDetails storage user = AddressToStakingDetails[msg.sender];
        /**
         * @dev calculating reward 
         */
        calcuateRewards(msg.sender);
        bool transferTokenToThisAddress = token.transferFrom(msg.sender,address(this),amount);
        require(transferTokenToThisAddress == true, "Unable to stake!!!");
        emit staked(msg.sender, block.timestamp, amount);
        user.startTime = block.timestamp;
        user.stakedAmount += amount;
        user.lastRewardClaimedAt =0;
        s_totalStakedTokens += amount;
        return transferTokenToThisAddress;
        }

    /**
     * @dev This function is used to unstake the staked token 
     * @param amount is the number of tokens users want to unstake
    */
    function unStakeTokens(uint256 amount) external returns (bool) {
        require(amount > 0,"Amount should be more than zero");
        StakingDetails storage user = AddressToStakingDetails[msg.sender];
        /**
         * @dev testing that the input amount is less than the user staked token value 
         */
        if (amount > user.stakedAmount ) revert TokenStaking_NotEnoughTokens();
        /**
         * @dev the user have to stake the tokens for atlest one day to unstake them
         */
        require(block.timestamp > user.startTime + 1 days,"You have to stake atleast one day to get rewards");
        /**
         * @dev calculating reward 
         */
        calcuateRewards(msg.sender);
        bool status = token.transfer(msg.sender, amount);
        require(status == true, "Unable to Unstake!!");

        user.endTime = block.timestamp;
        user.stakedAmount -= amount;
        s_totalStakedTokens -=amount;
        emit unStaked(msg.sender, block.timestamp);
        /**
         * 
         * @dev if the user has unstaked all the tokens then we reset all the details other than the totalRewardsClaimed & claimableRewards
        */
        if(user.stakedAmount == 0 ) {
        user.startTime =0;
        user.lastRewardClaimedAt = 0;
        user.endTime = 0;
        }
         /**
         * @dev  Updating the user.startTime to current time if the user still has staked tokens.
         */
        else{
            user.startTime = block.timestamp;
        }
        return status;
    }
    

    /**
     * @notice this function is used to claim the reward of staking 
    */
    function claimRewards(uint256 amount) external returns (bool) {
        StakingDetails storage user = AddressToStakingDetails[msg.sender];
          /**
         * @dev calculating reward 
         */
        calcuateRewards(msg.sender);
        if (user.claimableRewards <= 0) revert TokenStaking_NoRecordFound();
        if(amount > user.claimableRewards) revert TokenStaking_NotEnoughTokens();
        require(
            checkRewardsTokenBalance() > user.claimableRewards,
            "Contract balance too low to give rewards,try after some time"
        );
        bool status =token.transfer(msg.sender, amount);
        require(status == true, "Unable to Unstake!!");
        user.claimableRewards -= amount;
        user.totalRewardsClaimed += amount;
        s_totalRewardsGiven += amount;
        if(user.stakedAmount != 0){
        user.lastRewardClaimedAt = block.timestamp;
        }
        else{
        user.lastRewardClaimedAt = 0;
        }
        emit claimReward(msg.sender, block.timestamp, amount);
        return status;
    }

    /**
     * @dev this is the function which is used to calculate the reward of the user who stake tokens even without unstaking the tokens
     * @param staker is the address of the user who stakes the token
    */
    function calcuateRewards(address staker) public returns (uint256) {
        StakingDetails storage user = AddressToStakingDetails[staker];
        /**
         * @dev here the reward of the user is calculated till the current time from the time he last claimed reward, the rewards are only
         * claculate if he is a staker
         */
        if (user.stakedAmount == 0) 
        {
            user.claimableRewards =0;
            return  user.claimableRewards;
        }else{
        uint256 currentTime = block.timestamp;
        /**
         * @dev if the user has not claimed reawards then rewards are claculated from the startTime/time at which tokens where staked
         */
        uint256 durationInSeconds;
        if(user.lastRewardClaimedAt ==0){
            durationInSeconds = currentTime - user.startTime;
        }
        else {
            durationInSeconds = currentTime - user.lastRewardClaimedAt;
        }            
        user.claimableRewards += ((user.stakedAmount * durationInSeconds * s_annualRewardPercentage)/DENOMINATOR)/365 days;
        return (
            user.claimableRewards
        );  
        }
    }

    /**
     * @dev this is a  helper functuon used to check the contract balance of reward tokens
    */
    function checkRewardsTokenBalance() internal view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        return balance;
    }

}
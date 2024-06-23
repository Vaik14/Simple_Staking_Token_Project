// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Test, console} from "forge-std/Test.sol";
import {TokenStaking} from "../src/TokenStaking.sol";
import {DeployStaking} from "../script/DeployStaking.s.sol";
import {Token} from "../src/Token.sol";
import {DeployToken} from "../script/DeployToken.s.sol";

contract TokenStakingTest is Test {
    TokenStaking public tokenStaking;
    Token public token;

    address public constant USER_ONE = address(1);
    address public constant USER_TWO = address(2);
    address public constant USER_THREE = address(3);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant VALUE_TO_MINT = 1e18;

    function setUp() public {
        DeployToken deployerToken = new DeployToken();
        token = deployerToken.run();

        tokenStaking = new TokenStaking(address(token));
    }

    function testStakeTokensSucess() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 200 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 200 ether);
        tokenStaking.stakeTokens(100 ether);
    }

    /**
     * @dev tesing that calcuateRewards is called in stake & unstake function
     */

    function testStakeTokens() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 200 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 200 ether);
        tokenStaking.stakeTokens(100 ether);
        vm.warp(365 days);

        (
            uint startTime,
            uint endTime,
            uint stakedAmount,
            uint claimableRewards,
            uint lastRewardClaimedAt,
            uint totalRewardsClaimed
        ) = tokenStaking.AddressToStakingDetails(USER_ONE);
        console.log("startTime by USER_ONE", startTime);
        console.log("endTime by USER_ONE", endTime);
        console.log("Staked by USER_ONE", stakedAmount);
        console.log("claimableRewards by USER_ONE", claimableRewards);
        console.log("lastRewardClaimedAt by USER_ONE", lastRewardClaimedAt);
        console.log("totalRewardsClaimed by USER_ONE", totalRewardsClaimed);
        // testing rewards are calculated on unstaking token
        tokenStaking.unStakeTokens(10 ether);
        (
            uint startTime2,
            uint endTime2,
            uint stakedAmount2,
            uint claimableRewards2,
            uint lastRewardClaimedAt2,
            uint totalRewardsClaimed2
        ) = tokenStaking.AddressToStakingDetails(USER_ONE);
        console.log("startTime after Unstaking some token=>", startTime2);
        console.log("endTime after Unstaking some token=>", endTime2);
        console.log("Staked after Unstaking some token=>", stakedAmount2);
        console.log(
            "claimableRewards after Unstaking some token=>",
            claimableRewards2
        );
        console.log(
            "lastRewardClaimedAt after Unstaking some token=>",
            lastRewardClaimedAt2
        );
        console.log(
            "totalRewardsClaimed after Unstaking some token=>",
            totalRewardsClaimed2
        );
        vm.warp(370 days);
        // testing rewards are calculated on staking token
        tokenStaking.stakeTokens(10 ether);
        (
            uint startTime3,
            uint endTime3,
            uint stakedAmount3,
            uint claimableRewards3,
            uint lastRewardClaimedAt3,
            uint totalRewardsClaimed3
        ) = tokenStaking.AddressToStakingDetails(USER_ONE);
        console.log("startTime after Staking more token=>", startTime3);
        console.log("endTime after Staking more token=>", endTime3);
        console.log("Staked after Staking more token=>", stakedAmount3);
        console.log(
            "claimableRewards after Staking more token=>",
            claimableRewards3
        );
        console.log(
            "lastRewardClaimedAt after Staking more token=>",
            lastRewardClaimedAt3
        );
        console.log(
            "totalRewardsClaimed after Staking more token=>",
            totalRewardsClaimed3
        );
    }

    function testCalculateRewards() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 10 ether);
        tokenStaking.stakeTokens(10 ether);
        vm.warp(365 days);
        // expectedReward = ~3.6 ether;
        uint256 rewards = tokenStaking.calcuateRewards(USER_ONE);
        console.log("Rewards", rewards);
    }

    function testClaimRewards() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        token._mint(address(tokenStaking), 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 5 ether);
        tokenStaking.stakeTokens(5 ether);
        vm.warp(365 days);
        // "rewards 365 days  => ~1.8 ether"
        uint256 rewards = tokenStaking.calcuateRewards(USER_ONE);
        console.log("Rewards", rewards);
        tokenStaking.claimRewards(1.79 ether);
        console.log("Total Rewards Distributions =>",tokenStaking.s_totalRewardsGiven());

    }

    function testClaimRewardsFail() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 2 ether);
        tokenStaking.stakeTokens(2 ether);
        vm.warp(2 days);
        // "rewards 2 days  => 3945205479452054" claiming more than this
        vm.expectRevert();
        tokenStaking.claimRewards(4945205479452054);
        console.log("Total Rewards Distributions =>",tokenStaking.s_totalRewardsGiven());

    }

    // checking a user can't get more rewards after unstaking the tokens
    function testClaimRewardsLongerDurationFail() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 10 ether);
        tokenStaking.stakeTokens(10 ether);
        vm.warp(365 days);
        console.log("reward after 365 days");
        (, , , uint claimableRewards, , ) = tokenStaking
            .AddressToStakingDetails(USER_ONE);
        console.log("claimableRewards by USER_ONE", claimableRewards);
        tokenStaking.unStakeTokens(2 ether);
        uint256 rewards = tokenStaking.calcuateRewards(USER_ONE);
        console.log("Rewards", rewards);
        vm.warp(366 days);
        console.log("reward after 366 days");
        (, , , uint256 claimableRewards2, , ) = tokenStaking
            .AddressToStakingDetails(USER_ONE);

        console.log("claimableRewards by USER_ONE", claimableRewards2);
        assertEq(rewards, claimableRewards2);
    }

    function testUnStakeTokensFail() public {
        uint256 _value;
        vm.expectRevert();
        // unstaking tokens without staking shoudld revert
        tokenStaking.unStakeTokens(_value);
    }

    function testUnStakeTokensBeforeMinimumTime() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 2 ether);
        tokenStaking.stakeTokens(2 ether);
        vm.expectRevert();
        // unstaking tokens without before 1 day shoudld revert
        tokenStaking.unStakeTokens(2 ether);
    }

    function testUnstakingMoreThanStake() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 2 ether);
        tokenStaking.stakeTokens(2 ether);
        vm.warp(365 days);
        vm.expectRevert();
        tokenStaking.unStakeTokens(3 ether);
    }

    function testUnstakingSucess() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, 10 ether);
        vm.startPrank(USER_ONE);
        token.approve(address(tokenStaking), 10 ether);
        tokenStaking.stakeTokens(10 ether);
        vm.warp(365 days);
        (
            uint startTime,
            uint endTime,
            uint stakedAmount,
            uint claimableRewards,
            uint lastRewardClaimedAt,
            uint totalRewardsClaimed
        ) = tokenStaking.AddressToStakingDetails(USER_ONE);
        console.log("startTime  USER_ONE", startTime);
        console.log("endTime  USER_ONE", endTime);
        console.log("Staked  USER_ONE", stakedAmount);
        console.log("claimableRewards by USER_ONE", claimableRewards);
        console.log("lastRewardClaimedAt by USER_ONE", lastRewardClaimedAt);
        console.log("totalRewardsClaimed by USER_ONE", totalRewardsClaimed);
        uint256 rewards = tokenStaking.calcuateRewards(USER_ONE);
        console.log("Rewards after 1 year", rewards);
        tokenStaking.claimRewards(rewards);
        console.log("Total Rewards Distributions =>",tokenStaking.s_totalRewardsGiven());

        vm.warp(730 days);
        uint256 rewardsAfter = tokenStaking.calcuateRewards(USER_ONE);
        console.log("Rewards After 2 years", rewardsAfter);
        (
            uint startTimeAfter,
            uint endTimeAfter,
            uint stakedAmountAfter,
            uint claimableRewardsAfter,
            uint lastRewardClaimedAtAfter,
            uint totalRewardsClaimedAfter
        ) = tokenStaking.AddressToStakingDetails(USER_ONE);
        console.log("startTime  USER_ONE", startTimeAfter);
        console.log("endTime  USER_ONE", endTimeAfter);
        console.log("Staked  USER_ONE", stakedAmountAfter);
        console.log("claimableRewards by USER_ONE", claimableRewardsAfter);
        console.log(
            "lastRewardClaimedAt by USER_ONE",
            lastRewardClaimedAtAfter
        );
        console.log(
            "totalRewardsClaimed by USER_ONE",
            totalRewardsClaimedAfter
        );
    }

    //getters
    function testsAnnualRewardPercentage() public {
        assertEq(360, tokenStaking.s_annualRewardPercentage());
        assertEq(1000, tokenStaking.DENOMINATOR());
        assertEq(1 ether, tokenStaking.s_minimumStakingValue());
    }
}

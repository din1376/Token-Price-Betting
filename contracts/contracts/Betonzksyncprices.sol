// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Betonzksyncprices is Ownable, ReentrancyGuard {

    struct Asset {
        string symbol;
        address aggregatorAddress;
    }

    Asset[] public assets;

    function getAssetCount() external view returns (uint256) {
        return assets.length;
    }

    function getAsset(
        uint256 index
    ) external view returns (string memory, int256) {
        require(index < assets.length, "Invalid asset index");

        Asset memory asset = assets[index];
        return (asset.symbol, getLatestData(asset.aggregatorAddress));
    }

    function getLatestData(
        address aggregatorAddress
    ) internal view returns (int256) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(
            aggregatorAddress
        );
        (, int256 answer, , , ) = dataFeed.latestRoundData();
        return answer / 1e8;
    }

    struct Bet {
        string description;
        string option1;
        string option2;
        uint256 deadline;
        uint256 option1Votes;
        uint256 option2Votes;
        uint256 option1PoolUSDC;
        uint256 option2PoolUSDC;
        uint256 option1PoolETH;
        uint256 option2PoolETH;
        bool isFinalized;
        uint256 winningOption;
    }

    IERC20 public usdcToken;

    // get the prices using zksync chainlink pricefeeds
    AggregatorV3Interface internal dataFeed;
    uint256 public betCount;
    mapping(uint256 => Bet) public bets;
    mapping(uint256 => mapping(address => bool)) public userVoted;
    mapping(uint256 => mapping(address => uint256)) public userStakesUSDC;
    mapping(uint256 => mapping(address => uint256)) public userStakesETH;

    event BetCreated(uint256 indexed betId, string description, string option1, string option2, uint256 deadline);
    event VotePlaced(uint256 indexed betId, address indexed user, uint256 option, uint256 amountUSDC, uint256 amountETH);
    event BetFinalized(uint256 indexed betId, uint256 winningOption);
    event RewardsDistributed(uint256 indexed betId, uint256 totalRewardsUSDC, uint256 totalRewardsETH);
    event RewardWithdrawn(address indexed user, uint256 amountUSDC, uint256 amountETH);

    constructor(address _usdcToken) Ownable(msg.sender) {
        usdcToken = IERC20(_usdcToken);
        dataFeed = AggregatorV3Interface(0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1);

        assets.push(
            Asset("BTC/USD", 0x95Bc57e794aeb02E4a16eff406147f3ce2531F83)
        );
        assets.push(
            Asset("ETH/USD", 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF)
        );
        assets.push(
            Asset("LINK/USD", 0x894423C43cD7230Cd22a47B329E96097e6355292)
        );
        assets.push(
            Asset("DAI/USD", 0x3aE81863E2F4cdea95b0c96E9C3C71cf1e10EFFE)
        );
    }

    function createBet(string memory _description, string memory _option1, string memory _option2, uint256 _deadline) external  {
        require(_deadline > block.timestamp, "Invalid deadline");
        betCount++;
        bets[betCount] = Bet(_description, _option1, _option2, _deadline, 0, 0, 0, 0, 0, 0, false, 0);
        emit BetCreated(betCount, _description, _option1, _option2, _deadline);
    }

    function vote(uint256 _betId, uint256 _option, uint256 _amountUSDC, uint256 _amountETH) external payable nonReentrant {
        Bet storage bet = bets[_betId];
        require(bet.deadline > block.timestamp, "Voting period has ended");
        require(_option == 1 || _option == 2, "Invalid option");
        require(!userVoted[_betId][msg.sender], "User has already voted");
        require(_amountUSDC > 0 || _amountETH > 0, "Invalid amount");
        require(msg.value == _amountETH, "ETH amount mismatch");

        userVoted[_betId][msg.sender] = true;
        userStakesUSDC[_betId][msg.sender] = _amountUSDC;
        userStakesETH[_betId][msg.sender] = _amountETH;

        if (_option == 1) {
            bet.option1Votes++;
            bet.option1PoolUSDC += _amountUSDC;
            bet.option1PoolETH += _amountETH;
        } else {
            bet.option2Votes++;
            bet.option2PoolUSDC += _amountUSDC;
            bet.option2PoolETH += _amountETH;
        }

        if (_amountUSDC > 0) {
            usdcToken.transferFrom(msg.sender, address(this), _amountUSDC);
        }

        emit VotePlaced(_betId, msg.sender, _option, _amountUSDC, _amountETH);
    }

    function increaseBet(uint256 _betId, uint256 _amountUSDC, uint256 _amountETH) external payable nonReentrant {
        Bet storage bet = bets[_betId];
        require(bet.deadline > block.timestamp, "Beting period has ended");
        require(_amountUSDC > 0 || _amountETH > 0, "Invalid amount");
        require(msg.value == _amountETH, "ETH amount mismatch");
        require(userVoted[_betId][msg.sender], "User has not voted");

        uint256 userOption = userStakesUSDC[_betId][msg.sender] > 0 ? 1 : 2;
        userStakesUSDC[_betId][msg.sender] += _amountUSDC;
        userStakesETH[_betId][msg.sender] += _amountETH;

        if (userOption == 1) {
            bet.option1PoolUSDC += _amountUSDC;
            bet.option1PoolETH += _amountETH;
        } else {
            bet.option2PoolUSDC += _amountUSDC;
            bet.option2PoolETH += _amountETH;
        }

        if (_amountUSDC > 0) {
            usdcToken.transferFrom(msg.sender, address(this), _amountUSDC);
        }

        emit VotePlaced(_betId, msg.sender, userOption, _amountUSDC, _amountETH);
    }

    function finalizeBet(uint256 _betId, uint256 _winningOption) external onlyOwner {
        Bet storage bet = bets[_betId];
        require(bet.deadline <= block.timestamp, "Voting period has not ended");
        require(!bet.isFinalized, "Bet already finalized");
        require(_winningOption == 1 || _winningOption == 2, "Invalid winning option");

        bet.isFinalized = true;
        bet.winningOption = _winningOption;

        emit BetFinalized(_betId, _winningOption);
    }

    function distributeRewards(uint256 _betId) external onlyOwner nonReentrant {
        Bet storage bet = bets[_betId];
        require(bet.isFinalized, "Bet not finalized");

        uint256 totalPoolUSDC = bet.option1PoolUSDC + bet.option2PoolUSDC;
        uint256 totalPoolETH = bet.option1PoolETH + bet.option2PoolETH;
        uint256 totalRewardsUSDC = 0;
        uint256 totalRewardsETH = 0;

        for (uint256 i = 0; i < betCount; i++) {
            address user = address(uint160(i));
            uint256 userStakeUSDC = userStakesUSDC[_betId][user];
            uint256 userStakeETH = userStakesETH[_betId][user];

            if (userVoted[_betId][user] && (userStakeUSDC > 0 || userStakeETH > 0)) {
                uint256 userOption = userStakeUSDC > 0 ? 1 : 2;

                if (userOption == bet.winningOption) {
                    uint256 userRewardUSDC = (userStakeUSDC * totalPoolUSDC) / (bet.winningOption == 1 ? bet.option1PoolUSDC : bet.option2PoolUSDC);
                    uint256 userRewardETH = (userStakeETH * totalPoolETH) / (bet.winningOption == 1 ? bet.option1PoolETH : bet.option2PoolETH);
                    totalRewardsUSDC += userRewardUSDC;
                    totalRewardsETH += userRewardETH;

                    userStakesUSDC[_betId][user] = 0;
                    userStakesETH[_betId][user] = 0;

                    if (userRewardUSDC > 0) {
                        usdcToken.transfer(user, userRewardUSDC);
                    }
                    if (userRewardETH > 0) {
                        payable(user).transfer(userRewardETH);
                    }

                    emit RewardWithdrawn(user, userRewardUSDC, userRewardETH);
                }
            }
        }

        emit RewardsDistributed(_betId, totalRewardsUSDC, totalRewardsETH);
    }

    function getTotalPoolUSDC(uint256 _betId) external view returns (uint256) {
        Bet storage bet = bets[_betId];
        return bet.option1PoolUSDC + bet.option2PoolUSDC;
    }

    function getTotalPoolETH(uint256 _betId) external view returns (uint256) {
        Bet storage bet = bets[_betId];
        return bet.option1PoolETH + bet.option2PoolETH;
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (, int answer, , , ) = dataFeed.latestRoundData();
        return answer;
    }

    function getUserVote(uint256 _betId, address _user) external view returns (bool) {
        return userVoted[_betId][_user];
    }

    function getUserStakeUSDC(uint256 _betId, address _user) external view returns (uint256) {
        return userStakesUSDC[_betId][_user];
    }

    function getUserStakeETH(uint256 _betId, address _user) external view returns (uint256) {
        return userStakesETH[_betId][_user];
    }
}
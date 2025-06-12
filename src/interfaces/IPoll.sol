//SPDX-License-Identifier:MIT
pragma solidity 0.8.28;

interface IPoll {
    struct Poll {
        string question;
        string[] options;
        uint256 startTime;
        uint256 endTime;
        address erc20;
        address owner;
    }

    function createPoll(
        string memory question,
        string[] memory options,
        uint256 startTime,
        uint256 endTime,
        address erc20
    ) external payable;

    function getMinFee() external view returns (uint256);

    function getAllPolls() external view returns (Poll[] memory);

    function getPollById(uint256 pollId) external view returns (Poll memory);
}

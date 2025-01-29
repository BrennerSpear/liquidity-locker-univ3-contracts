// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// UNCX by SDDTech reserves all rights on this code. You may not copy these contracts.

pragma solidity 0.8.19;

import "./IUNCX_ProofOfReservesV2_UniV3.sol";
import "../uniswap-updated/INonfungiblePositionManager.sol";

/**
 * @title UniV3LockHelper
 * @dev A helper contract to simplify locking Uniswap V3 LP positions with sensible defaults
 */
contract UniV3LockHelper {
    IUNCX_ProofOfReservesV2_UniV3 public immutable locker;
    INonfungiblePositionManager public immutable nftPositionManager;
    
    // Default lock duration (6 months)
    uint256 public constant DEFAULT_LOCK_DURATION = 180 days;
    
    constructor(
        address _locker,
        address _nftPositionManager
    ) {
        require(_locker != address(0), "Invalid locker address");
        require(_nftPositionManager != address(0), "Invalid NFT position manager");
        locker = IUNCX_ProofOfReservesV2_UniV3(_locker);
        nftPositionManager = INonfungiblePositionManager(_nftPositionManager);
    }

    /**
     * @notice Locks a Uniswap V3 LP position with sensible defaults
     * @param nftId The NFT ID of the position to lock
     * @param owner The owner of the lock (who can withdraw after unlock)
     * @param lockDuration Optional custom lock duration (in seconds). If 0, uses DEFAULT_LOCK_DURATION
     * @dev Before calling this function, approve this contract to transfer your NFT
     */
    function lockPosition(
        uint256 nftId,
        address owner,
        uint256 lockDuration
    ) external payable returns (uint256 lockId) {
        // Transfer the NFT to this contract first
        nftPositionManager.safeTransferFrom(msg.sender, address(this), nftId);
        
        // Approve the locker to take the NFT
        nftPositionManager.approve(address(locker), nftId);
        
        // Prepare lock parameters with sensible defaults
        IUNCX_ProofOfReservesV2_UniV3.LockParams memory params = IUNCX_ProofOfReservesV2_UniV3.LockParams({
            nftPositionManager: nftPositionManager,
            nft_id: nftId,
            dustRecipient: owner, // Send any dust to the owner
            owner: owner,
            additionalCollector: address(0), // No additional collector by default
            collectAddress: owner, // Auto-collect fees to the owner
            unlockDate: block.timestamp + (lockDuration == 0 ? DEFAULT_LOCK_DURATION : lockDuration),
            countryCode: 0, // Default country code
            feeName: "DEFAULT", // Use default fee structure
            r: new bytes[](0) // Empty array as required
        });
        
        // Lock the position
        lockId = locker.lock{value: msg.value}(params);
    }

    /**
     * @notice Locks a Uniswap V3 LP position with the default 6-month lock duration
     * @param nftId The NFT ID of the position to lock
     * @param owner The owner of the lock (who can withdraw after unlock)
     */
    function lockPositionWithDefaultDuration(
        uint256 nftId,
        address owner
    ) external payable returns (uint256 lockId) {
        return lockPosition(nftId, owner, 0);
    }
}

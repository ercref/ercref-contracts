// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Open source repo: http://zzn.li/ercref

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity >=0.7.0 <0.9.0;

/// The EIP-165 identifier of this interface is 0x0c44c20d
interface IEIP2135 {

  /// @notice The consume function consumes a token every time it succeeds.
  /// @param _consumer the address of consumer of this token. It doesn't have
  ///                  to be the EOA or contract Account that initiates the TX.
  /// @param _assetId  the NFT asset being consumed
  /// @param _data     extra data passed in for consume for extra message
  ///                  or future extension.
  function consume(address _consumer, uint256 _assetId, uint256 _amount, bytes calldata _data) external returns(bool _success);

  /// @notice The interface to check whether an asset is consumable.
  /// @param _consumer the address of consumer of this token. It doesn't have
  ///                  to be the EOA or contract Account that initiates the TX.
  /// @param _assetId  the NFT asset being consumed.
  /// @param _amount   the amount of the asset being consumed.
  function isConsumableBy(address _consumer, uint256 _assetId, uint256 _amount) external view returns (bool _consumable);

  /// @notice The event emitted when there is a successful consumption.
  /// @param consumer the address of consumer of this token. It doesn't have
  ///                  to be the EOA or contract Account that initiates the TX.
  /// @param assetId  the NFT asset being consumed
  /// @param amount   the amount of the asset being consumed.
  /// @param data     extra data passed in for consume for extra message
  ///                  or future extension.
  event OnConsumption(address indexed consumer, uint256 indexed assetId, uint256 amount, bytes data);
}

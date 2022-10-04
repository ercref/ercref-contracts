// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity ^0.8.9;

interface IERC5453 {
   event OnEndorsed(
      bytes4 indexed _methodSelector,
      address[] endorsers
   );
}

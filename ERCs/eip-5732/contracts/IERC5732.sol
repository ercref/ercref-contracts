// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Open source repo: http://zzn.li/ercref

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity >=0.7.0 <0.9.0;

/// The EIP-165 identifier of this interface is 0xdd691946
interface IERC_COMMIT {
    event Commit(bytes32 _commitment, bytes _extraData);
    function commit(bytes32 _commitment, bytes calldata _extraData) payable external;
}

import "@openzeppelin/contracts/utils/Address.sol";

contract SimpleForwarder {
    function forward(
        address[] calldata targets,
        uint256[] calldata values,
        uint256[] calldata /*gasLimits*/,
        bytes[] calldata calldatas
    ) public {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }
}

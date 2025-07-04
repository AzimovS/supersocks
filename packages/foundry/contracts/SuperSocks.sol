//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "solady/auth/Ownable.sol";
import "solady/tokens/ERC1155.sol";
import "solady/utils/Base64.sol";
import "solady/utils/LibString.sol";
import "solady/tokens/ERC20.sol";
import "./Metadata.sol";

/**
 * A smart contract that allows minting SuperSocks with USDC
 * @author azf20
 */
contract SuperSocks is Ownable, ERC1155 {
    // Custom errors
    error NoUSDCToWithdraw();
    error InvalidTokenId();
    error InsufficientUSDC();

    event CreatorBalanceWithdrawn(address indexed creator, uint256 amount);
    event SockCreated(uint256 indexed sockId, address indexed creator);
    event CreatorPaid(uint256 indexed sockId, address indexed creator, uint256 amount);
    event SocksPaid(address indexed sockRecipient, uint256 total, uint256 creatorFee);

    uint256 public usdcPrice;
    uint256 public slippage;
    address public immutable usdc;
    Metadata public metadata;
    uint256 public creatorFee;

    uint256 public totalCreatorBalance;

    mapping(uint256 => address) public creator;
    mapping(address => uint256) public creatorBalance;

    // Constructor: Called once on contract deployment
    // Check packages/foundry/deploy/Deploy.s.sol
    constructor(address _metadata, address _usdc) {
        _initializeOwner(msg.sender);
        usdcPrice = 100000; // 1 USDC (6 decimals) TODO: UPDATE BEFORE DEPLOY
        creatorFee = 10;
        slippage = 1; // 1% slippage
        usdc = _usdc;
        metadata = Metadata(_metadata);
    }

    /// @dev Returns the token collection name.
    function name() public pure returns (string memory) {
        return "SuperSocks";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure returns (string memory) {
        return "SOCKS";
    }

    function contractURI() public pure returns (string memory) {
        string memory json = '{"name": "SuperSocks","description":"Onchain customizable socks."}';
        return string.concat("data:application/json;utf8,", json);
    }

    /// @dev Updates the renderer contract
    function setMetadata(Metadata _metadata) external onlyOwner {
        metadata = _metadata;
    }

    function setPrice(uint256 _price) external onlyOwner {
        usdcPrice = _price;
    }

    function setCreatorFee(uint256 _creatorFee) external onlyOwner {
        creatorFee = _creatorFee;
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function uri(uint256 id) public view override returns (string memory) {
        return metadata.tokenURI(id);
    }

    /// @dev Sets the USDC price for minting
    function setUsdcPrice(uint256 _price) external onlyOwner {
        usdcPrice = _price;
    }

    function _mint(address to, uint256[] memory sockIds, uint256[] memory amounts, uint256 valuePerSock) internal {

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < sockIds.length; i++) {
            if(!metadata.validateTokenId(sockIds[i])) revert InvalidTokenId();
            if (creator[sockIds[i]] == address(0)) {
                creator[sockIds[i]] = to;
                emit SockCreated(sockIds[i], to);
            }
            uint256 creatorFeeAmount = valuePerSock * amounts[i] * creatorFee / 100;
            creatorBalance[creator[sockIds[i]]] += creatorFeeAmount;
            totalAmount += amounts[i];
            emit CreatorPaid(sockIds[i], creator[sockIds[i]], creatorFeeAmount);
        }

        totalCreatorBalance += valuePerSock * totalAmount * creatorFee / 100;

        _batchMint(to, sockIds, amounts, "");
    }

    /// @dev Mints a new token by paying in USDC
    function mint(address to, uint256[] memory sockIds, uint256[] memory amounts, uint256 usdcAmount) public {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        uint256 requiredUsdc = usdcPrice * totalAmount * (100 - slippage) / 100;
        if (usdcAmount < requiredUsdc) revert InsufficientUSDC();

        // Transfer USDC from user to contract
        ERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);

        uint256 valuePerSock = usdcAmount / totalAmount;

        _mint(to, sockIds, amounts, valuePerSock);

        emit SocksPaid(to, usdcAmount, (usdcAmount * creatorFee) / 100);
    }

    /// @dev Withdraws accumulated USDC (after swapping ETH to USDC)
    function withdraw() public onlyOwner {
        uint256 usdcBalance = ERC20(usdc).balanceOf(address(this));
        uint256 ownerShare = usdcBalance - totalCreatorBalance;
        if (ownerShare > 0) {
            ERC20(usdc).transfer(owner(), ownerShare);
        }
        emit CreatorBalanceWithdrawn(owner(), ownerShare);
    }

    function withdrawCreatorBalance() public {
        if (creatorBalance[msg.sender] == 0) revert NoUSDCToWithdraw();
        uint256 amount = creatorBalance[msg.sender];
        totalCreatorBalance -= amount;
        creatorBalance[msg.sender] = 0;
        ERC20(usdc).transfer(msg.sender, amount);
        emit CreatorBalanceWithdrawn(msg.sender, amount);
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable { }
}

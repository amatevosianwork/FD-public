// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title FooDriverToken
 * @dev This contract implements an ERC20 token with additional features like permit and upgradability.
 *      The token is intended for use within the FooDriver platform.
 * @notice This token includes functionalities for managing public and private token sales, distributing initial token supply to various stakeholders, and providing upgrade mechanisms.
 */
contract FooDriverToken is Initializable, ERC20Upgradeable, ERC20PermitUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    uint256 public constant INITIAL_SUPPLY = 2_000_000_000 * 10 ** 18;
    uint256 public constant MARKETING_PERCENT = 19;
    uint256 public constant LIQUIDITY_PERCENT = 19;
    uint256 public constant STABILITY_PERCENT = 10;
    uint256 public constant TEAM_PERCENT = 20;
    uint256 public constant FOUNDER_PERCENT = 14;
    uint256 public constant AIRDROP_PERCENT = 2;
    uint256 public constant PRIVATE_SALE_PERCENT = 8;
    uint256 public constant PUBLIC_SALE_PERCENT = 8;
    uint256 public publicSaleAmountLeft;
    uint256 public privateSaleAmountLeft;
    enum SaleStatus {
        NotStarted,
        Started,
        Ended
    }
    SaleStatus public privateSale;
    SaleStatus public publicSale;
    uint256 public purchaseRate;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the token by setting up roles, minting the initial supply to specified addresses, and preparing the token for public and private sales.
     * @param initialAuthority The address that will be granted the DEFAULT_ADMIN_ROLE and UPGRADER_ROLE.
     * @param marketingWallet The address that will receive the marketing share of the token supply.
     * @param liquidityWallet The address that will receive the liquidity share of the token supply.
     * @param stabilityWallet The address that will receive the stability reserve of the token supply.
     * @param airdropWallet The address that will receive the airdrop portion of the token supply.
     * @param teamWallet The address that will receive the team's share of the token supply.
     * @param founderWallet The address that will receive the founder's share of the token supply.
     */
    function initialize(address initialAuthority, address marketingWallet, address liquidityWallet, address stabilityWallet, address airdropWallet, address teamWallet, address founderWallet) initializer public {
        __ERC20_init("FooDriverToken", "FDT");
        __ERC20Permit_init("FooDriverToken");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE,initialAuthority);
        _mint(_msgSender(), INITIAL_SUPPLY  );
        _mint(marketingWallet, (INITIAL_SUPPLY/100) * MARKETING_PERCENT);
        _mint(liquidityWallet, (INITIAL_SUPPLY/100) * LIQUIDITY_PERCENT);
        _mint(stabilityWallet, (INITIAL_SUPPLY/100) * STABILITY_PERCENT);
        _mint(airdropWallet, (INITIAL_SUPPLY/100) * AIRDROP_PERCENT);
        _mint(teamWallet, (INITIAL_SUPPLY/100) * TEAM_PERCENT);
        _mint(founderWallet, (INITIAL_SUPPLY/100) * FOUNDER_PERCENT);
        publicSaleAmountLeft = (INITIAL_SUPPLY/100) * PUBLIC_SALE_PERCENT;
        privateSaleAmountLeft = (INITIAL_SUPPLY/100) * PRIVATE_SALE_PERCENT;
    }

    /**
     * @notice Sets the purchase rate for tokens sold during public and private sales.
     * @param _newPurchaseRate The new rate at which tokens are sold (number of tokens per wei).
     */
    function setPurchaseRate(uint256 _newPurchaseRate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        purchaseRate = _newPurchaseRate;
    }

    /**
     * @notice Starts the public sale of tokens.
     */
    function startPublicSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(publicSale == SaleStatus.NotStarted,'Public Sale already started');
       publicSale = SaleStatus.Started;
    }

    /**
     * @notice Ends the public sale of tokens and mints any remaining tokens to a specified address.
     * @param _mintRemainingTokensTo The address that will receive the remaining unsold public sale tokens.
     */
    function endPublicSale(address _mintRemainingTokensTo) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(publicSale == SaleStatus.Started,'Public Sale not started or already ended');
        publicSale = SaleStatus.Ended;
        _mint(_msgSender(), publicSaleAmountLeft);
    }

    /**
     * @notice Allows users to purchase tokens during the public sale.
     */
    function purchasePublic() public payable {
        require(purchaseRate > 0, "Purchase Rate is 0");
        require(publicSale == SaleStatus.Started, "Public Sale is not started");
        uint256 payout = msg.value * purchaseRate;
        require(publicSaleAmountLeft >= payout, "Public Sale amount insufficient");
        publicSaleAmountLeft -= payout;
        _mint(_msgSender(), payout);
    }

    /**
     * @notice Starts the private sale of tokens.
     */
    function startPrivateSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(privateSale == SaleStatus.NotStarted,'Private Sale already started');
        privateSale = SaleStatus.Started;
    }

    /**
     * @notice Ends the private sale of tokens and mints any remaining tokens to a specified address.
     * @param _mintRemainingTokensTo The address that will receive the remaining unsold private sale tokens.
     */
    function endPrivateSale(address _mintRemainingTokensTo) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(privateSale == SaleStatus.Started,'Private Sale not started or already ended');
        privateSale = SaleStatus.Ended;
        _mint(_msgSender(), privateSaleAmountLeft);
    }

    /**
     * @notice Allows users to purchase tokens during the private sale.
     */
    function purchasePrivate() public payable {
        require(purchaseRate > 0, "Purchase Rate is 0");
        require(privateSale == SaleStatus.Started, "Private Sale is not started");
        uint256 payout = msg.value * purchaseRate;
        require(privateSaleAmountLeft >= payout, "Private Sale amount insufficient");
        privateSaleAmountLeft -= payout;
        _mint(_msgSender(), payout);
    }

    /**
     * @dev Internal function to authorize upgrades to new implementations.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}

}

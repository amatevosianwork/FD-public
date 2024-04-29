// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFooDriverRegistry} from "./interfaces/IFooDriverRegistry.sol";
import {IFooDriverBank} from "./interfaces/IFooDriverBank.sol";
import {IFooDriverFactory} from "./interfaces/IFooDriverFactory.sol";
import {IFooDriverStore} from "./interfaces/IFooDriverStore.sol";

/**
 * @title FooDriverRegistry
 * @dev This contract serves as the central registry for the FooDriver platform and handling role management.
 * @notice This contract is upgradeable and makes use of the UUPS pattern for potential future upgrades.
 */
contract FooDriverRegistry is Initializable, UUPSUpgradeable, AccessControlUpgradeable, IFooDriverRegistry {
    address public bank;
    address public token;
    address public factory;

    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    bytes32 public constant STORE_ROLE = keccak256("STORE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    /**
      * @dev Initializes the FooDriverRegistry contract, setting up default roles.
     */
    function initialize() initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(REGISTRY_ROLE, address(this));
    }

    modifier onlySuperAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotSuperAdmin();
        }
        _;
    }
    modifier onlyUpgrader() {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) {
            revert NotUpgrader();
        }
        _;
    }

    /**
     * @notice Sets the ERC20 token address used in the platform.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function setToken(address _tokenAddress) public onlySuperAdmin {
        token = _tokenAddress;
    }

    /**
     * @notice Sets the address of the FooDriverBank contract.
     * @param _bankAddress The address of the FooDriverBank.
     */
    function setBank(address _bankAddress) public onlySuperAdmin {
        bank = _bankAddress;
    }

    /**
     * @notice Sets the address of the FooDriverFactory contract.
     * @param _factoryAddress The address of the FooDriverFactory.
     */
    function setFactory(address _factoryAddress) public onlySuperAdmin {
        factory = _factoryAddress;
    }

    /**
     * @notice Creates a new store and grants it the STORE_ROLE.
     * @param _storeId The identifier for the new store.
     * @return storeAddress The address of the newly created store.
     */
    function createStore(string memory _storeId) public onlySuperAdmin returns (address storeAddress)  {
        address store = IFooDriverFactory(factory).fCreateStore(_storeId, address(this), bank, token);
        _grantRole(STORE_ROLE, store);
        return store;
    }

    /**
     * @notice Retrieves the address of a store by its ID.
     * @param _storeId The ID of the store to retrieve.
     * @return IFooDriverStore The interface of the store contract.
     */
    function getStoreById(string memory _storeId) public view returns (IFooDriverStore) {
        address storeAddress = IFooDriverFactory(factory).fGetStoreById(_storeId);
        return IFooDriverStore(storeAddress);
    }

    /**
     * @notice Retrieves a specific order from a store by the store and order IDs.
     * @param _storeId The ID of the store.
     * @param _orderId The ID of the order.
     * @return IFooDriverStore.Order The order details.
     */
    function getStoreOrderById(string memory _storeId, string memory _orderId) public view returns (IFooDriverStore.Order memory) {
        address storeAddress = IFooDriverFactory(factory).fGetStoreById(_storeId);
        return IFooDriverStore(storeAddress).getOrderById(_orderId);
    }

    /**
     * @notice Sets a new commissions wallet for the FooDriverBank.
     * @param _newCommissionWallet The address of the new commissions wallet.
     */
    function setCommissionWalletForBank(address _newCommissionWallet) external onlySuperAdmin {
        IFooDriverBank(bank).setCommissionWallet(_newCommissionWallet);
    }

    /**
     * @notice Directs a store to create an order with specified parameters.
     * @param _orderParams The parameters necessary to create an order.
     */
    function createOrderForStore(OrderParams memory _orderParams) public onlySuperAdmin {
        getStoreById(_orderParams.storeId).createOrder(
            _orderParams.orderId,
            _orderParams.customerAddress,
            _orderParams.amount,
            _orderParams.deliveryAmount,
            _orderParams.storeGuaranteeDepositPercent,
            _orderParams.customerGuaranteeDepositPercent,
            _orderParams.courierGuaranteeDepositPercent,
            _orderParams.appCommissionPercent,
            _orderParams.weightGoodsDepositAmount);
    }

    /**
     * @notice Confirms an order in a specified store.
     * @param _storeId The ID of the store.
     * @param _orderId The ID of the order to confirm.
     */
    function confirmOrderForStore(string memory _storeId, string memory _orderId) public onlySuperAdmin {
        getStoreById(_storeId).confirmOrder(_orderId);
    }

    /**
     * @notice Assigns a courier to an order in a specified store.
     * @param _storeId The ID of the store.
     * @param _orderId The ID of the order.
     * @param _courierAddress The address of the courier.
     */
    function addCourierToOrderInStore(string memory _storeId, string memory _orderId, address _courierAddress) public onlySuperAdmin {
        getStoreById(_storeId).addCourierToOrder(_orderId, _courierAddress);
    }

    /**
     * @notice Changes the courier for an existing order in a specified store.
     * @param _storeId The ID of the store.
     * @param _orderId The ID of the order.
     * @param _courierAddress The new courier's address.
     */
    function changeCourierInOrderInStore(string memory _storeId, string memory _orderId, address _courierAddress) public onlySuperAdmin {
        getStoreById(_storeId).changeCourierInOrder(_orderId, _courierAddress);
    }

    /**
     * @notice Releases funds for a completed order in a specified store.
     * @param _storeId The ID of the store.
     * @param _orderId The ID of the order.
     * @param _weightGoodsReturn Amount in weight returned, if applicable.
     */
    function releaseFundsForOrderInStore(string memory _storeId, string memory _orderId, uint256 _weightGoodsReturn) public onlySuperAdmin {
        getStoreById(_storeId).releaseOrder(_orderId, _weightGoodsReturn);
    }

    /**
     * @notice Refunds all or some participants of an order in a specified store.
     * @param _storeId The ID of the store.
     * @param _orderId The ID of the order.
     * @param toCustomer Should the customer be refunded?
     * @param toStore Should the store be refunded?
     * @param toCourier Should the courier be refunded?
     */
    function refundOrderInStore(string memory _storeId, string memory _orderId, bool toCustomer,
        bool toStore,
        bool toCourier) public onlySuperAdmin {
        getStoreById(_storeId).refundOrder(_orderId, toCustomer, toStore, toCourier);
    }

    /**
     * @notice Withdraws ERC20 tokens from a specified store.
     * @param _storeId The ID of the store.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     * @param _to The recipient of the tokens.
     */
    function withdrawERC20TokenInStore(string memory _storeId, address _tokenAddress, uint256 _amount, address _to) public onlySuperAdmin {
        getStoreById(_storeId).withdrawERC20Token(_tokenAddress, _amount, _to);
    }

    /**
     * @notice Withdraws ERC20 tokens from the bank.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     * @param _to The recipient of the tokens.
     */
    function withdrawERC20TokenInBank(address _tokenAddress, uint256 _amount, address _to) public onlySuperAdmin {
        IFooDriverBank(bank).withdrawERC20Token(_tokenAddress, _amount, _to);
    }

    /**
     * @dev Internal function to authorize an upgrade to a new implementation of this contract.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyUpgrader
    override
    {}
}

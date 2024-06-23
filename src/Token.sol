//  SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev this function should only be called after minting the 90% of supply &
        ownership should be transfred to the vesting contract
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Token token contract
 */

contract Token is Ownable {
    ///////////////////
    // Errors
    ///////////////////
    error Token__ZeroAddress();
    error Token__AlreadyMinted();
    error Token__AlreadySet();

    ///////////////////
    // State Variables
    ///////////////////
    string public s_name;
    string public s_symbol;
    uint8 public decimals;
    bool s_mintAllowed = true;
    uint256 public s_totalSupply;
    uint256 public s_Max_Tokens;

    address public s_VestingContractAddress;

    //Tokenomics
    address public s_AddressForSale; //21%
    uint256 public s_AllocationForForSale;

    address public s_AddressForRewardsAndDistribution; //59%
    uint256 public s_AllocationRewardsAndDistribution;

    //10% vesting 48 months(4 years) releasing tokens daily
    uint256 public s_AllocationForTeamTokens;

    address public s_AddressForLiquidityAndReserve; //6%
    uint256 public s_AllocationForForLiquidityAndReserve;

    address public s_AddressForPartnershipAndAcquisition; //4%
    uint256 public s_AllocationForPartnershipAndAcquisition;

    ///////////////////
    // Events
    ///////////////////
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    event Mint(address indexed to, uint256 value);

    ///////////////////
    // Mappings
    ///////////////////
    /// @dev Mapping address with number of tokens
    mapping(address => uint256) public balanceOf;
    /// @dev Mapping allowance given by a user to another
    mapping(address => mapping(address => uint256)) public allowance;

    ///////////////////
    // Modifier
    ///////////////////

    modifier onlyVesting() {
        require(msg.sender == s_VestingContractAddress);
        _;
    }


    ///////////////////
    // Functions
    ///////////////////
    constructor() {
        s_symbol = "token";
        s_name = "TOKEN";
        decimals = 18;
        s_Max_Tokens = 1000000000 * 10**uint256(decimals);

        // Tokens Allocation
        s_AllocationForForSale = 210_000_000 * 10**uint256(decimals);
        s_AllocationRewardsAndDistribution = 590_000_000 * 10**uint256(decimals);
        s_AllocationForTeamTokens = 100_000_000 * 10**uint256(decimals);
        s_AllocationForForLiquidityAndReserve = 60_000_000 * 10**uint256(decimals);
        s_AllocationForPartnershipAndAcquisition = 40_000_000 * 10**uint256(decimals);
    }    


    /**
     * @param SaleAddress: Address on which the allocated funds for initial public or private sales.
     */
    function mintForSale(address SaleAddress) external onlyOwner {
        if (s_AddressForSale != address(0)) {
            revert Token__AlreadyMinted();
        }
        if (SaleAddress == address(0)) {
            revert Token__ZeroAddress();
        }
        s_AddressForSale = SaleAddress;
        _mint(SaleAddress, s_AllocationForForSale);
    }

    /**
     * @param LiquidityAndReserve: Address on which the allocated funds of Liquidity & Reserve are assigned
     */
    function mintForLiquidityAndReserve(address LiquidityAndReserve)external onlyOwner {
        if (s_AddressForLiquidityAndReserve != address(0)) {
            revert Token__AlreadyMinted();
        }
        if (LiquidityAndReserve == address(0)) {
            revert Token__ZeroAddress();
        }
        s_AddressForLiquidityAndReserve = LiquidityAndReserve;
        _mint(LiquidityAndReserve, s_AllocationForForLiquidityAndReserve);
    }

    /**
     * @param PartnershipAndAcquisition: Address on which the allocated funds of Partnership & Acquisition are assigned
     */
    function mintForPartnershipAndAcquisition(address PartnershipAndAcquisition)external onlyOwner {
        if (s_AddressForPartnershipAndAcquisition != address(0)) {
            revert Token__AlreadyMinted();
        }
        if (PartnershipAndAcquisition == address(0)) {
            revert Token__ZeroAddress();
        }
        s_AddressForPartnershipAndAcquisition = PartnershipAndAcquisition;
        _mint(
            PartnershipAndAcquisition,
            s_AllocationForPartnershipAndAcquisition
        );
    }

    /**
     * @param _to: address to which funds will be assigned
     * @param _value: The number of funds which will be assigned
     */
    function _mint(address _to, uint256 _value)public onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert Token__ZeroAddress();
        }
        require(
            s_Max_Tokens >= s_totalSupply + _value,
            "Max supply reached!!!"
        );
        require(s_mintAllowed, "Max supply reached!!");
        balanceOf[_to] += _value;
        s_totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Mint(_to, _value);
        return true;
    }

    /**
     * @param _to: address to which funds will be transfered from the callers account
     * @param _value: The number of funds which will be send from senders to receivers account
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @param _spender: address to which is given permission to spend funds on behave of assigner
     * @param _value: The number of funds which will be assigned
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * @param _from: Address from which the funds are spend
     * @param _to: The number of funds which will be transfered
     * @param _value : The number of funds which will be spend
     */
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @param _value: The number of funds which will be destroyed
     */
    function burn(uint256 _value) public returns (bool) {
        require(
            balanceOf[msg.sender] >= _value,
            "You don't have enough balance!!"
        );
        require(_value > 0, "You can't burn zero funds");
        balanceOf[msg.sender] -= _value;
        s_totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @param _from: Address from which the funds are spend
     * @param _to: The number of funds which will be transfered
     * @param _value : The number of funds which will be spend
     */
    function _transfer(address _from,address _to, uint256 _value) internal {
        if (_to == address(0)) {
            revert Token__ZeroAddress();
        }

        require(balanceOf[_from] >= _value, "You don't have enough funds");
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint256 balanceBeforeTransfer = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceBeforeTransfer == (balanceOf[_from] + balanceOf[_to]));
    }
}

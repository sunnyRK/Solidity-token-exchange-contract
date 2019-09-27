pragma solidity ^0.5.11;

contract Escrow {

    uint256 public USDpriceInInr;
    struct Transactions {
        uint256 tokenInINR;
        uint256 tokenInUSD;
        uint256 time;
        address sender;
    }
    mapping (bytes32 => Transactions) public allTransactions;
    
    bool public IsSender;
    bool public IsReciever;
    mapping (string => uint256) private _balanceOfUSD;
    mapping (string => uint256) private _balanceOfINR;
    
    constructor(uint256 __totalSupply) public{
        _balanceOfUSD["USD"] = __totalSupply;
        _balanceOfINR["INR"] = __totalSupply*70;
    }

    function chaekINRTokensExist(uint256 _INRValue, uint256 _USDValue) public returns (bool) {
        require(_INRValue > 0);
        require(_INRValue <= _balanceOfINR["INR"], "Insufficient INR funds in escrow.");
        _balanceOfUSD["USD"] = _balanceOfUSD["USD"] + _USDValue;
        _balanceOfINR["INR"] = _balanceOfINR["INR"] - _INRValue;
        return true;
    }
    
    function chaekUSDTokensExist(uint256 _INRValue, uint256 _USDValue) public returns (bool) {
        require(_USDValue > 0);
        require(_USDValue <= _balanceOfUSD["USD"], "Insufficient USD funds in escrow.");
        _balanceOfINR["INR"] = _balanceOfINR["INR"] + _INRValue;
        _balanceOfUSD["USD"] = _balanceOfUSD["USD"] - _USDValue;
        return true;
    }

    // Escrow gives permission to exchanging tokens by changing the status true for IsReciever
    function changeStatus(uint256 inrVal, uint256 usdVal, uint256 time, address sender) public returns (bytes32) {
        bytes32 transactionId = bytes32(keccak256(abi.encodePacked(msg.sender,now)));
        allTransactions[transactionId].tokenInINR = inrVal;
        allTransactions[transactionId].tokenInUSD = usdVal;
        allTransactions[transactionId].time = time;
        allTransactions[transactionId].sender = sender;
        IsSender = true;
        IsReciever = true;
        return transactionId;
    }
    
    function IsSenderAccept() public view returns (bool) {
        return IsSender;
    }
    
    function IsRecieverAccept() public view returns (bool) {
        return IsReciever;
    }
    
    function getEscroeINR() public view returns (uint256) {
        return _balanceOfINR["INR"];
    }
    
    function getEscrowUSD() public view returns (uint256) {
        return _balanceOfUSD["USD"];
    }
    
    function getTransactionDetails(bytes32 transactionId) public view returns(uint256, uint256, uint256, address) {
        return (
            allTransactions[transactionId].tokenInINR,
            allTransactions[transactionId].tokenInUSD,
            allTransactions[transactionId].time,
            allTransactions[transactionId].sender
        );
    }
}

contract USD {
    string public constant symbol = "USD";
    uint256 private __totalSupply = 10000;
    Escrow escrow;

    mapping (address => uint256) private _uBalanceOfUSD;
    mapping (address => uint256) private _uBalanceOfINR;
    
    constructor(Escrow _escrow) public{
        _uBalanceOfUSD[msg.sender] = __totalSupply;
        _uBalanceOfINR[msg.sender] = __totalSupply*70;
        escrow = _escrow;
    }
    
    function balanceOf(address _addr) public view returns (uint256 balance) {
        return _uBalanceOfUSD[_addr];
    }
    
    function transferINRToUSD(uint256 _INRvalue, address sender) public returns (bytes32){
        require(_INRvalue > 0);
        require(_uBalanceOfINR[msg.sender] >= _INRvalue, "Insufficient INR funds in USDcontract.");
        uint256 USDval = _INRvalue/70;
        
        bool IsSuccess = escrow.chaekUSDTokensExist(_INRvalue, USDval);
        require(IsSuccess);
        bytes32 transactionId = escrow.changeStatus(_INRvalue, USDval, now, msg.sender);
        bool IsSenderAccepted = escrow.IsSenderAccept();
        bool IsRecieverAccepted = escrow.IsRecieverAccept();
        
        require(IsSenderAccepted && IsRecieverAccepted);
        _uBalanceOfUSD[msg.sender] = _uBalanceOfUSD[msg.sender] + USDval;
        _uBalanceOfINR[msg.sender] = _uBalanceOfINR[msg.sender] - _INRvalue;
        
        return transactionId;
    }
    
    function getINR() public view returns (uint256) {
        return _uBalanceOfINR[msg.sender];
    }
    
    function getUSD() public view returns (uint256) {
        return _uBalanceOfUSD[msg.sender];
    }
}

contract INR {
    string public constant symbol = "INR";
    uint256 private __totalSupply = 10000;
    Escrow escrow;

    mapping (address => uint256) private _iBalanceOfUSD;
    mapping (address => uint256) private _iBalanceOfINR;
    
    constructor(Escrow _escrow) public{
        _iBalanceOfUSD[msg.sender] = __totalSupply;
        _iBalanceOfINR[msg.sender] = __totalSupply*70;
        escrow = _escrow;
    }
    
    function balanceOf(address _addr) public view returns (uint balance) {
        return _iBalanceOfINR[_addr];
    }
    
    function transferUSDtoINR(uint256 _USDvalue, address sender) public returns (bytes32){
        require(_USDvalue > 0);
        require(_iBalanceOfUSD[msg.sender] >= _USDvalue, "Insufficient USD funds in INRcontract.");
        uint256 INRval = _USDvalue*70;
        
        bool IsSuccess = escrow.chaekINRTokensExist(INRval, _USDvalue);
        require(IsSuccess);
        
        bytes32 transactionId = escrow.changeStatus(INRval, _USDvalue, now, msg.sender);
        bool IsSenderAccepted = escrow.IsSenderAccept();
        bool IsRecieverAccepted = escrow.IsRecieverAccept();
        
        require(IsSenderAccepted && IsRecieverAccepted);
        _iBalanceOfINR[msg.sender] = _iBalanceOfINR[msg.sender] + INRval;
        _iBalanceOfUSD[msg.sender] = _iBalanceOfUSD[msg.sender] - _USDvalue;
        
        return transactionId;
    }
    
    
    function getINR() public view returns (uint256) {
        return _iBalanceOfINR[msg.sender];
    }
    
    function getUSD() public view returns (uint256) {
        return _iBalanceOfUSD[msg.sender];
    }
}

contract deploy {
    Escrow escrow = new Escrow(10000);
    INR private inrObj = new INR(escrow);
    USD private usdObj = new USD(escrow);
    
    ///////////////////  INR Functions //////////////////////
    // This function for INR contract _value
    // It will transfer USD value to INR value
    function transferUSDtoINR(uint256 _giveUSDvalue) public {
        inrObj.transferUSDtoINR(_giveUSDvalue, msg.sender);    
    }
    
    // It will fetch INR and USD values of INRcontract value
    function checkINRContracValue() public view returns (uint256, uint256) {
        uint256 inr = inrObj.getINR();
        uint256 usd = inrObj.getUSD();
        return ( 
            inr, 
            usd
        );
    }
    
    ///////////////////  USD Functions //////////////////////
    // This function for USD contract _value
    // It will transfer INR value to USD value
    function transferINRToUSD(uint256 _giveINRvalue) public {
        usdObj.transferINRToUSD(_giveINRvalue, msg.sender);
    }
    
    // It will fetch INR and USD values of USDcontract value
    function checkUSDContracValue() public view returns (uint256, uint256) {
        uint256 inr = usdObj.getINR();
        uint256 usd = usdObj.getUSD();
        return ( 
            inr, 
            usd
        );
    }
    
    ///////////////////  Escrow Functions //////////////////////
    // It will fetch INR and USD values of USDcontract value
    function checkEscrowTokensValue() public view returns (uint256, uint256) {
        uint256 inr = escrow.getEscroeINR();
        uint256 usd = escrow.getEscrowUSD();
        return ( 
            inr, 
            usd
        );
    }
}



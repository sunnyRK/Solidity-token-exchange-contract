pragma solidity ^0.5.11;

contract Escrow {

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
    
    function DepositINRToken(uint256 _INRvalue) public {
        require(_INRvalue > 0);
        _balanceOfINR["INR"] = _balanceOfINR["INR"] + _INRvalue; 
    }
    
    function DepositUSDToken(uint256 _USDvalue) public {
        require(_USDvalue > 0);
        _balanceOfUSD["USD"] = _balanceOfUSD["USD"] + _USDvalue; 
    }
    
    function deductUSD(uint256 _USDvalue) public {
        _balanceOfUSD["USD"] = _balanceOfUSD["USD"] - _USDvalue; 
    }
    
    function deductINR(uint256 _INRvalue) public {
        _balanceOfINR["INR"] = _balanceOfINR["INR"] - _INRvalue; 
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

    mapping (address => uint256) private _uBalanceOfUSD;
    mapping (address => uint256) private _uBalanceOfINR;
    
    constructor() public{
        _uBalanceOfUSD[msg.sender] = __totalSupply;
        _uBalanceOfINR[msg.sender] = __totalSupply;
    }
    
    function balanceOf(address _addr) public view returns (uint256 balance) {
        return _uBalanceOfUSD[_addr];
    }
    
    function transferINRToUSD(uint256 times, uint256 _INRvalue, address sender) public returns (bytes32){
        require(_INRvalue > 0);
        require(_uBalanceOfINR[msg.sender] >= _INRvalue);
        uint256 USDval = _INRvalue/70;
        
        Escrow escrow = new Escrow();
        escrow.DepositINRToken(_INRvalue);
        bytes32 transactionId = escrow.changeStatus(_INRvalue, USDval, now, msg.sender);
        bool IsSenderAccepted = escrow.IsSenderAccept();
        bool IsRecieverAccepted = escrow.IsRecieverAccept();
        
        require(IsSenderAccepted && IsRecieverAccepted);
        _uBalanceOfUSD[msg.sender] = _uBalanceOfUSD[msg.sender] + USDval;
        _uBalanceOfINR[msg.sender] = _uBalanceOfINR[msg.sender] - _INRvalue;
        
        escrow.deductINR(_INRvalue);
        
        return transactionId;
    }
    
    function setNewValue(uint256 _INRvalue, uint256 _USDvalue) public {
        _uBalanceOfUSD[msg.sender] = _uBalanceOfUSD[msg.sender] + _USDvalue;
        _uBalanceOfINR[msg.sender] = _uBalanceOfINR[msg.sender] - _INRvalue;
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

    mapping (address => uint256) private _iBalanceOfUSD;
    mapping (address => uint256) private _iBalanceOfINR;
    
    constructor() public{
        _iBalanceOfUSD[msg.sender] = __totalSupply;
        _iBalanceOfINR[msg.sender] = __totalSupply;
    }
    
    function balanceOf(address _addr) public view returns (uint balance) {
        return _iBalanceOfINR[_addr];
    }
    
    function transferUSDtoINR(uint256 times, uint256 _USDvalue, address sender) public returns (bytes32){
        require(_USDvalue > 0);
        require(_iBalanceOfINR[msg.sender] >= _USDvalue);
        uint256 INRval = _USDvalue*70;
        
        Escrow escrow = new Escrow();
        escrow.DepositUSDToken(_USDvalue);
        bytes32 transactionId = escrow.changeStatus(INRval, _USDvalue, now, msg.sender);
        bool IsSenderAccepted = escrow.IsSenderAccept();
        bool IsRecieverAccepted = escrow.IsRecieverAccept();
        
        require(IsSenderAccepted && IsRecieverAccepted);
        _iBalanceOfINR[msg.sender] = _iBalanceOfINR[msg.sender] + INRval;
        _iBalanceOfUSD[msg.sender] = _iBalanceOfUSD[msg.sender] - _USDvalue;
        
        escrow.deductUSD(_USDvalue);
    
        return transactionId;
    }
    
    function setNewValue(uint256 _INRvalue, uint256 _USDvalue) public {
        _iBalanceOfINR[msg.sender] = _iBalanceOfINR[msg.sender] + _INRvalue;
        _iBalanceOfUSD[msg.sender] = _iBalanceOfUSD[msg.sender] - _USDvalue;
    }
    
    function getINR() public view returns (uint256) {
        return _iBalanceOfINR[msg.sender];
    }
    
    function getUSD() public view returns (uint256) {
        return _iBalanceOfUSD[msg.sender];
    }
}

contract deploy {
    INR private inrObj = new INR();
    USD private usdObj = new USD();
    
    ///////////////////  INR Functions //////////////////////
    
    // This function for INR contract _value
    // It will transfer USD value to INR value
    function transferUSDtoINR(uint256 _value) public {
        inrObj.transferUSDtoINR(10, _value, msg.sender);    
        usdObj.setNewValue(_value*70, _value);
    }
    
    // It will fetch INR and USD values of INRcontract value
    function checkINRContracValue() public view returns (uint256, uint256) {
        // INR inrObj = new INR();
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
    function transferINRToUSD(uint256 _value) public {
        usdObj.transferINRToUSD(10, _value, msg.sender);
        inrObj.setNewValue(_value, _value/10);
    }
    
    // It will fetch INR and USD values of USDcontract value
    function checkUSDContracValue() public view returns (uint256, uint256) {
        // INR inrObj = new INR();
        uint256 inr = usdObj.getINR();
        uint256 usd = usdObj.getUSD();
        return ( 
            inr, 
            usd
        );
    }
}



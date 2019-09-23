pragma solidity ^0.5.11;

contract Escrow {
    bool public IsSender;
    bool public IsReciever;
    mapping (string => uint) private _balanceOfUSD;
    mapping (string => uint) private _balanceOfINR;

    function changeStatus() public{
        IsSender = true;
        IsReciever = true;
    }
    
    function IsSenderAccept() public view returns (bool) {
        return IsSender;
    }
    
    function IsRecieverAccept() public view returns (bool) {
        return IsReciever;
    }
    
    function DepositINRToken(uint _INRvalue) public {
        require(_INRvalue > 0);
        _balanceOfINR["INR"] = _balanceOfINR["INR"] + _INRvalue; 
    }
    
    function DepositUSDToken(uint _USDvalue) public {
        require(_USDvalue > 0);
        _balanceOfUSD["USD"] = _balanceOfUSD["USD"] + _USDvalue; 
    }
    
    function deductUSD(uint _USDvalue) public {
        _balanceOfUSD["USD"] = _balanceOfUSD["USD"] - _USDvalue; 
    }
    
    function deductINR(uint _INRvalue) public {
        _balanceOfINR["INR"] = _balanceOfINR["INR"] - _INRvalue; 
    }
}

contract USD {
    string public constant symbol = "USD";
    uint private __totalSupply = 10000;

    mapping (address => uint) private _uBalanceOfUSD;
    mapping (address => uint) private _uBalanceOfINR;
    
    constructor() public{
        _uBalanceOfUSD[msg.sender] = __totalSupply;
        _uBalanceOfINR[msg.sender] = __totalSupply;
    }
    
    function balanceOf(address _addr) public view returns (uint balance) {
        return _uBalanceOfUSD[_addr];
    }
    
    function transferINRToUSD(uint times, uint _INRvalue, address sender) public{
        require(_INRvalue > 0);
        require(_uBalanceOfINR[msg.sender] >= _INRvalue);
        Escrow escrow = new Escrow();
        escrow.DepositINRToken(_INRvalue);
        escrow.changeStatus();
        bool IsSenderAccepted = escrow.IsSenderAccept();
        bool IsRecieverAccepted = escrow.IsRecieverAccept();
        require(IsSenderAccepted && IsRecieverAccepted);
        uint USDval = _INRvalue/70;
        _uBalanceOfUSD[msg.sender] = _uBalanceOfUSD[msg.sender] + USDval;
        _uBalanceOfINR[msg.sender] = _uBalanceOfINR[msg.sender] - _INRvalue;
        escrow.deductINR(_INRvalue);
    }
    
    function setNewValue(uint _INRvalue, uint _USDvalue) public {
        _uBalanceOfUSD[msg.sender] = _uBalanceOfUSD[msg.sender] + _USDvalue;
        _uBalanceOfINR[msg.sender] = _uBalanceOfINR[msg.sender] - _INRvalue;
    }
    
    function getINR() public view returns (uint) {
        return _uBalanceOfINR[msg.sender];
    }
    
    function getUSD() public view returns (uint) {
        return _uBalanceOfUSD[msg.sender];
    }
}

contract INR {
    string public constant symbol = "INR";
    uint private __totalSupply = 10000;

    mapping (address => uint) private _iBalanceOfUSD;
    mapping (address => uint) private _iBalanceOfINR;
    
    constructor() public{
        _iBalanceOfUSD[msg.sender] = __totalSupply;
        _iBalanceOfINR[msg.sender] = __totalSupply;
    }
    
    function balanceOf(address _addr) public view returns (uint balance) {
        return _iBalanceOfINR[_addr];
    }
    
    function transferUSDtoINR(uint times, uint _USDvalue, address sender) public{
        require(_USDvalue > 0);
        require(_iBalanceOfINR[msg.sender] >= _USDvalue);
        Escrow escrow = new Escrow();
        escrow.DepositUSDToken(_USDvalue);
        escrow.changeStatus();
        bool IsSenderAccepted = escrow.IsSenderAccept();
        bool IsRecieverAccepted = escrow.IsRecieverAccept();
        require(IsSenderAccepted && IsRecieverAccepted);
        uint INRval = _USDvalue*70;
        _iBalanceOfINR[msg.sender] = _iBalanceOfINR[msg.sender] + INRval;
        _iBalanceOfUSD[msg.sender] = _iBalanceOfUSD[msg.sender] - _USDvalue;
        escrow.deductUSD(_USDvalue);
    }
    
    function setNewValue(uint _INRvalue, uint _USDvalue) public {
        _iBalanceOfINR[msg.sender] = _iBalanceOfINR[msg.sender] + _INRvalue;
        _iBalanceOfUSD[msg.sender] = _iBalanceOfUSD[msg.sender] - _USDvalue;
    }
    
    function getINR() public view returns (uint) {
        return _iBalanceOfINR[msg.sender];
    }
    
    function getUSD() public view returns (uint) {
        return _iBalanceOfUSD[msg.sender];
    }
}

contract deploy {
    INR private inrObj = new INR();
    USD private usdObj = new USD();
    function transferUSDtoINR(uint _value) public {
        inrObj.transferUSDtoINR(10, _value, msg.sender);    
        usdObj.setNewValue(_value*70, _value);
    }
    
    function transferINRToUSD(uint _value) public {
        usdObj.transferINRToUSD(10, _value, msg.sender);
        inrObj.setNewValue(_value, _value/10);
    }
    
    function checkINRContracValue() public view returns (uint, uint) {
        // INR inrObj = new INR();
        uint inr = inrObj.getINR();
        uint usd = inrObj.getUSD();
        return ( 
            inr, 
            usd
        );
    }
    
    function checkUSDContracValue() public view returns (uint, uint) {
        // INR inrObj = new INR();
        uint inr = usdObj.getINR();
        uint usd = usdObj.getUSD();
        return ( 
            inr, 
            usd
        );
    }
}



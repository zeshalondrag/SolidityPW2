// SPDX-License-Identifier: GPL-3.0
// Первая строчка - лицензия

pragma solidity >=0.8.2 <0.9.0;

contract EstateAgency {
    enum EstateType { House, Flat, Loft }
    enum AdStatus { Opened, Closed }
    uint256 balance;

    struct Estate {
        uint size;
        address estateAddress;
        address owner;
        EstateType esType;
        bool isActive;
        uint idEstate;
    }

    struct Advertisement { 
        address owner;
        address buyer; 
        uint price;
        uint idEstate;
        uint dateTime;
        AdStatus adStatus;
    }

    Estate[] public estates;
    Advertisement[] public ads; 

    mapping(address => uint) public balances;

    event estateCreated(address owner, uint idEstate, uint dateTime, EstateType esType);
    event adCreated(address owner, uint idAd, uint dateTime, uint idEstate, uint price); 
    event estateStatusChanged(address owner, uint dateTime, uint idEstate, bool isActive); 
    event adStatusChanged(address owner, uint dateTime, uint idAd, uint idEstate, AdStatus adStatus);
    event fundsBack(address to, uint amount, uint dateTime);
    event estatePurchased(address adOwner, address buyer, uint idAd, uint idEstate, AdStatus adStatus, uint dateTime, uint price); 
    event BalanceAdded(address _user, uint256 _amount);
    event Withdrawal(address _to, uint256 _amount);


    modifier enoughValue(uint value, uint price){
       require(value >= price, unicode"У вас недостаточно средств");
        _; //здесь будет продолжать свою работу функция, если условие истино
    }

    modifier onlyEstateOwner(uint idEstate){
        require(estates[idEstate].owner == msg.sender, unicode"Вы не владелец данной недвижимости");
        _;
    }

    modifier onlyAdOwner(uint idAd){
        require(ads[idAd].owner == msg.sender, unicode"Вы не владелец данного объявления");
        _;
    }

    modifier isActiveEstate(uint idEstate){
        require(estates[idEstate].isActive, unicode"Данная недвижимость недоступна");
        _;
    }

    modifier isClosedAd(uint idAd){
        require(ads[idAd].adStatus == AdStatus.Opened, unicode"Данное объявление закрыто");
        _;
    }

    function pay() public payable {
        require(msg.value > 0, unicode"Значение должно быть больше 0");
        balance += msg.value;
        emit BalanceAdded(msg.sender, msg.value);
    }

    function createEstate(uint _size, EstateType _esType, address _estateAddress, uint _idEstate) public {
    estates.push(Estate({
        size: _size,
        estateAddress: _estateAddress,
        owner: msg.sender,
        esType: _esType,
        isActive: true,
        idEstate: _idEstate
    }));
    emit estateCreated(msg.sender, _idEstate, block.timestamp, _esType);
    }


    function createAd(uint idEstate, uint price) public onlyEstateOwner(idEstate) isActiveEstate(idEstate) {
        ads.push(Advertisement(msg.sender, address(0), price, idEstate, block.timestamp, AdStatus.Opened));
        emit adCreated(msg.sender, ads.length, block.timestamp, idEstate, price);
    }

    function updateEstateStatus(uint idEstate, bool newStatus) public onlyEstateOwner(idEstate) {
    estates[idEstate].isActive = newStatus;
    emit estateStatusChanged(msg.sender, block.timestamp, idEstate, newStatus);
    if (!newStatus) {
        for (uint i = 0; i < ads.length; i++) {
            if (ads[i].idEstate == idEstate && ads[i].adStatus == AdStatus.Opened) {
                ads[i].adStatus = AdStatus.Closed;
                emit adStatusChanged(msg.sender, block.timestamp, i, idEstate, AdStatus.Closed);
            }
        }
    }
    }

    function updateAdStatus(uint idAd) public onlyEstateOwner(ads[idAd].idEstate) isActiveEstate(ads[idAd].idEstate) {
    require(ads[idAd].adStatus == AdStatus.Opened, unicode"Объявление уже закрыто");
    ads[idAd].adStatus = AdStatus.Closed;
    emit adStatusChanged(msg.sender, block.timestamp, idAd, ads[idAd].idEstate, AdStatus.Closed);
    }

    function buyEstate(uint idEstate) public payable {
        require(estates[idEstate].isActive, unicode"Данная недвижимость НЕ в статусе active");
        require(msg.value >= ads[idEstate].price, unicode"Недостаточно средств для приобретения");
        require(address(this).balance >= msg.value, unicode"Недостаточно средств на контракте");
        require(estates[idEstate].owner != msg.sender, unicode"Вы не можете купить свою собственную недвижимость");

        payable(estates[idEstate].owner).transfer(msg.value);

        ads[idEstate].adStatus = AdStatus.Closed;
        estates[idEstate].isActive = false;

        balances[msg.sender] -= ads[idEstate].price;
        emit fundsBack(address(this), msg.value, block.timestamp);
        emit estatePurchased(estates[idEstate].owner, msg.sender, ads.length - 1, idEstate, AdStatus.Closed, block.timestamp, msg.value);
    }

    function withdraw(uint256 _amount) public {
        require(_amount <= address(this).balance, unicode"Недостаточный баланс");
        require(_amount > 0, unicode"Сумма вывода должна быть больше 0");
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    } 

    function getBalance() public view returns (uint256) {
        return  address(this).balance;
    }

    function getAds() public view returns (Advertisement[] memory) {
        return ads;
    } 

    function getEstates() public view returns (Estate[] memory) {
        return estates;
    } 
}

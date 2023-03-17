// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Lock {
    address public ERC20Address;

    uint256 contractCreationTime;

    uint256 public seedSaleQ = 4500000;
    uint256 public privateSaleQ = 15000000;
    uint256 public publicSaleQ = 7500000;
    uint256 liquidityQ = 7500000;

    uint256 public usedSeedSaleQ;
    uint256 public usedPrivateSaleQ;
    uint256 public usedPublicSaleQ;

    uint8 public seedPrice = 25;
    uint8 public privatePrice = 20;
    uint8 public publicPrice = 45;

    address liquidityAddress;

    /*
    [0] -business
    [1] -software
    [2] -marketing
    [3] -bonus
    [4] -team
    [5] -reserve
    [6] -partners
    */
    struct vesting {
        address receiver;
        uint256 quantity;
        uint256 cliff;
        uint256 ending;
        uint256 withdrawn;
    }

    vesting[] public vestingInfo;

    mapping(address => uint256[]) roomNumbers;
    mapping(address => uint256[]) quantity;
    mapping(address => uint256[]) timeStart;
    mapping(address => uint256[]) cliff;
    mapping(address => uint256[]) vestingTime;
    mapping(address => uint256) public withdrawn;
    
    // @notice this is hardcoded information. Ideally you would want this information outside of contract. This is just to save time 
    constructor(
        address _businessA,
        address _softwareA,
        address _marketingA,
        address _bonusA,
        address _teamA,
        address _reserveA,
        address _partnersA,
        address _liquidityA,
        address _parentERC20
    ) {
        liquidityAddress = _liquidityA;
        ERC20Address = _parentERC20;
        contractCreationTime = block.timestamp;
        vesting memory businessVesting = vesting(
            _businessA,
            9000000,
            31560000,
            63120000,
            0
        );
        vestingInfo.push(businessVesting);
        vesting memory softwareVesting = vesting(
            _softwareA,
            22500000,
            47340000,
            78900000,
            0
        );
        vestingInfo.push(softwareVesting);
        vesting memory marketingVesting = vesting(
            _marketingA,
            18000000,
            7890000,
            55230000,
            0
        );
        vestingInfo.push(marketingVesting);
        vesting memory bonusVesting = vesting(
            _bonusA,
            19500000,
            2630000,
            42080000,
            0
        );
        vestingInfo.push(bonusVesting);
        vesting memory teamVesting = vesting(
            _teamA,
            15000000,
            31560000,
            78900000,
            0
        );
        vestingInfo.push(teamVesting);
        vesting memory reserveVesting = vesting(
            _reserveA,
            22500000,
            15780000,
            47340000,
            0
        );
        vestingInfo.push(reserveVesting);
        vesting memory partnersVesting = vesting(
            _partnersA,
            9000000,
            13150000,
            60490000,
            0
        );
        vestingInfo.push(partnersVesting);
    }

    function publicBuy(uint256 _tokens) public payable {
        require(usedPublicSaleQ + _tokens <= publicSaleQ, "Not enough tokens left");
        require(
            msg.value >= ((_tokens * publicPrice) / 100) * 1 ether,
            "Not enough ether"
        );
        uint _unlock = _tokens / 100 * 25;
        usedPublicSaleQ += _tokens;
        quantity[msg.sender].push(_tokens);
        timeStart[msg.sender].push(block.timestamp);
        cliff[msg.sender].push(5260000);
        vestingTime[msg.sender].push(21040000);
        withdrawn[msg.sender] += _unlock;
        IERC20(ERC20Address).transfer(msg.sender, _unlock);
    }

    function privateBuy(uint256 _tokens) public payable {
        require(usedPrivateSaleQ + _tokens <= privateSaleQ, "Not enough tokens left");
        require(
            msg.value >= ((_tokens * privatePrice) / 100) * 1 ether,
            "Not enough ether"
        );
        uint _unlock = _tokens / 100 * 5;
        usedPrivateSaleQ += _tokens;
        quantity[msg.sender].push(_tokens);
        timeStart[msg.sender].push(block.timestamp);
        cliff[msg.sender].push(5260000);
        vestingTime[msg.sender].push(47340000);
        withdrawn[msg.sender] += _unlock;
        IERC20(ERC20Address).transfer(msg.sender, _unlock);
    }

    function seedBuy(uint256 _tokens) public payable {
        require(usedSeedSaleQ + _tokens <= seedSaleQ, "Not enough tokens left");
        require(
            msg.value >= ((_tokens * seedPrice) / 100) * 1 ether,
            "Not enough ether"
        );
        uint _unlock = _tokens / 100 * 5;
        usedSeedSaleQ += _tokens;
        quantity[msg.sender].push(_tokens);
        timeStart[msg.sender].push(block.timestamp);
        cliff[msg.sender].push(13150000);
        vestingTime[msg.sender].push(31560000);
        withdrawn[msg.sender] += _unlock;
        IERC20(ERC20Address).transfer(msg.sender, _unlock);
    }

    function _withdrawableAmount(address _user) public view returns (uint256) {
        uint256 all;
        uint256 _timestamp = block.timestamp;
        for (uint256 i = 0; i < cliff[_user].length; i++) {
            if (_timestamp >= timeStart[_user][i] + vestingTime[_user][i]) {
                all += quantity[_user][i] - withdrawn[_user];
            } else if (_timestamp >= (timeStart[_user][i] + cliff[_user][i])) {
                uint256 _timeTillNow = _timestamp - timeStart[_user][i];
                uint256 timePassed = (_timeTillNow * 100) / vestingTime[_user][i];
                all += ((quantity[_user][i] * timePassed / 100) - withdrawn[_user]);
            }
            
        } 
        return (all);
    }

    function _withdrawableInsiderVesting(uint8 _type)
        public
        view
        returns (uint256)
    {
        if (
            block.timestamp >= contractCreationTime + vestingInfo[_type].ending
        ) {
            return (vestingInfo[_type].quantity - vestingInfo[_type].withdrawn);
        } else if (
            block.timestamp >= contractCreationTime + vestingInfo[_type].cliff
        ) {
            uint256 _temp = (block.timestamp * 100) /
                (contractCreationTime + vestingInfo[_type].ending);
            return (((vestingInfo[_type].quantity / 100) * _temp) -
                vestingInfo[_type].withdrawn);
        } else {
            return (0);
        }
    }

    function withdraw(uint256 _amount) public {
        require(
            _withdrawableAmount(msg.sender) >= _amount,
            "Not enough balance"
        );
        withdrawn[msg.sender] += _amount;
        IERC20(ERC20Address).transfer(msg.sender, _amount);
    }

    function withdrawInsider(uint256 _amount, uint8 _type) public {
        uint256 _allowedAmount = _withdrawableInsiderVesting(_type);
        require(_allowedAmount >= _amount, "Not enough balance");
        vestingInfo[_type].withdrawn += _amount;
        IERC20(ERC20Address).transfer(vestingInfo[_type].receiver, _amount);
    }

}

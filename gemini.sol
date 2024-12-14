pragma solidity ^0.8.0;

contract Agreement {

    enum State { draft, active, terminated, violated }
    State public currentState;

    struct Party {
        string name;
        address payable wallet;
        bool signed;
    }
    Party public partyA;
    Party public partyB;

    uint256 public executionDate;
    uint256 public endDate;
    uint256 public effectivePeriod;
    bool public isRenewed;
    uint256 public renewPeriod;
    uint256 public terminationNoticePeriod;
    uint256 public terminationNoticeDate;
    uint256 public terminationDate;
    uint256 public nextPriceIncreaseDate;
    uint256 public adCompensateNoticeDate;
    uint256 public adCompensateFinishDate;

    string public violationDetails;
    bool public isTerminated;


    uint256 public adCompensatePeriod;
    uint256[] public prices;
    uint256 public priceIncreaseLimit;
    string public IPRights;
    bool public infringementStatus;
    bool public adImpressionStatus;
    bool public transferStatus;
    address public currentActor; // Track the current actor



     modifier inState(State _state) {
        require(currentState == _state, "Invalid state transition");
        _;
    }

    modifier onlyParty() {
        require(msg.sender == partyA.wallet || msg.sender == partyB.wallet, "Unauthorized party.");
        _;
    }


    constructor(address payable _partyA, address payable _partyB) {
        partyA.name = "Women.com";
        partyB.name = "eDiets";
        partyA.wallet = _partyA;
        partyB.wallet = _partyB;
        effectivePeriod = 2 * 365 days;
        renewPeriod = 12 * 30 days;
        terminationNoticePeriod = 60 days;
        prices.push(10000);
        priceIncreaseLimit = 20 * 100; // percentage to actual value
        IPRights = partyA.name;        
        currentState = State.draft; // Initial state
        
    }

    event StateTransition(State from, State to);
    event sign_agreement();
    event contract_renewal_check();
    event notify_termination();
    event terminate_agreement();
    event breach_advertisement();
    event transfer_contract();
    event adjust_payment();
    event guarantee_impressions();
    event compensate_period();
    event compensate_impressions();
    event use_intellectual_property();
    event brand_infringement();


    function signAgreement() public onlyParty inState(State.draft) {        
        if (msg.sender == partyA.wallet) {
            partyA.signed = true;
        } else {
            partyB.signed = true;
        }

        if (partyA.signed && partyB.signed) {
            executionDate = block.timestamp;
            endDate = executionDate + effectivePeriod;
            nextPriceIncreaseDate = executionDate + 60 days;
            currentState = State.active;
            emit StateTransition(State.draft, State.active);
        }
        emit sign_agreement();
    }

 function contractRenewalCheck() public inState(State.active)  {
        require(block.timestamp > endDate && !isTerminated, "Renewal conditions not met.");

        isRenewed = true;
        endDate = endDate + renewPeriod;
        emit contract_renewal_check();
    }


    function notifyTermination() public onlyParty inState(State.active) {
        require(block.timestamp < endDate - terminationNoticePeriod, "Too late to notify termination.");

        terminationNoticeDate = block.timestamp;
        emit notify_termination();
    }

    function terminateAgreement() public inState(State.active) {
        require(block.timestamp < endDate && terminationNoticeDate != 0, "Termination conditions not met.");

        terminationDate = block.timestamp;
        isTerminated = true;
        currentState = State.terminated;
        emit terminate_agreement();
         emit StateTransition(State.active, State.terminated);
    }



    function breachAdvertisement(bool competitorAdvertisement) public onlyParty inState(State.active) {
        require(competitorAdvertisement, "No competitor advertisement detected.");
         currentState = State.violated;
        violationDetails = "Advertising on competing platform";
         emit StateTransition(State.active, State.violated);
        emit breach_advertisement();
    }

    function transferContract(bool controlChange, bool isCompetitor, address _transferParty) public onlyParty inState(State.active){
        require(controlChange && !isCompetitor, "Transfer conditions not met.");

        transferStatus = true;
        currentActor = _transferParty;
        emit transfer_contract();
    }


    function adjustPayment(uint256 price) public  inState(State.active) {
        require(msg.sender == partyA.wallet, "Unauthorized party.");
        require(block.timestamp > nextPriceIncreaseDate, "Not eligible for price adjustment yet.");

         // Get last year's price
        uint256 lastYearPrice = 0;
        if(prices.length > 0 && block.timestamp > nextPriceIncreaseDate){
             lastYearPrice = prices[prices.length - 1];
        }
        require(price * 100 <= lastYearPrice * (100 + priceIncreaseLimit), "Price increase exceeds limit.");

        prices.push(price);

        nextPriceIncreaseDate = nextPriceIncreaseDate + 365 days;
        emit adjust_payment();
    }

    function guaranteeImpressions(uint256 adImpressions) public inState(State.active) {
        require(msg.sender == partyA.wallet, "Unauthorized party.");
        require(adImpressions < 13000000, "Ad impressions requirement met.");
        adImpressionStatus = false;

        emit guarantee_impressions();
    }



    function compensatePeriod(uint256 _adCompensatePeriod) public inState(State.active) {
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        require(!adImpressionStatus, "Ad impression status is true.");

        adCompensateNoticeDate = block.timestamp;
        adCompensatePeriod = _adCompensatePeriod;
        emit compensate_period();
    }


    function compensateImpressions() public inState(State.active) {
        require(msg.sender == partyA.wallet, "Unauthorized party.");
         require(block.timestamp <= adCompensateNoticeDate + adCompensatePeriod, "Compensation period expired.");
        adImpressionStatus = true;
        adCompensateFinishDate = block.timestamp;
        emit compensate_impressions();

    }



    function useIntellectualProperty(bool IPUsageCheck) public onlyParty inState(State.active) {
        require(!IPUsageCheck, "IP usage within contract scope.");

        currentState = State.violated;
        violationDetails = "IP usage is out of contract scope.";
         emit StateTransition(State.active, State.violated);
        emit use_intellectual_property();
    }


    function brandInfringement(bool _brandInfringement) public onlyParty inState(State.active) {
        require((block.timestamp > endDate || (terminationDate != 0 && block.timestamp > terminationDate)) && _brandInfringement, "Brand infringement conditions not met.");

        currentState = State.violated;
        infringementStatus = true;
         emit StateTransition(State.active, State.violated);

        emit brand_infringement();

    }
}

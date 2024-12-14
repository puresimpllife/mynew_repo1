pragma solidity ^0.8.0;

enum State { draft, active, terminated, violated }

struct Party {
    string name;
    address payable wallet;
    bool signed;
}

contract Agreement {
    Party public partyA;
    Party public partyB;
    uint256 public executionDate;
    uint256 public endDate;
    uint256 public renewalPeriod;
    uint256 public terminationDate;
    uint256 public terminationNoticePeriod;
    uint256 public terminationNoticeDate;
    uint256 public violatedDate;
    bool public competingProductsRestriction;
    bool public isRenewed;
    bool public writtenApproval;
    bool public auditRights;
    uint256 public auditProvideDate;
    uint256 public auditPeriod;
    uint256 public seasonAdThreshold;
    uint256 public addTotalFee;
    uint256 public addTotalDemand;
    uint256 public payPercentage; // Represented as basis points e.g., 1500 for 15%
    uint256 public recommendFee;
    uint256[] public incomes;
    address[] public dataOwnership;
    uint256 public nextAdFeeDate;
    uint256 public nextIncomePayDate;
    bool public transferStatus;
    State public currentState;

    event sign_agreement();
    event renew_agreement();
    event terminate_agreement();
    event breach_advertisement();
    event transfer_approval();
    event transfer_contract();
    event pay_on_success_candidate();
    event pay_income();
    event ad_fee_requirements();
    event ad_fee_violate();
    event audit_provide();
    event StateTransition(State from, State to);

    constructor(address payable _partyA, address payable _partyB) {
        partyA = Party("VerticalNet", _partyA, false);
        partyB = Party("LeadersOnline", _partyB, false);
        endDate = timestampToDate("2001-06-15");
        renewalPeriod = 365 days;
        terminationNoticePeriod = 90 days;
        competingProductsRestriction = true;
        auditRights = true;
        auditPeriod = 12 * 30 days;
        seasonAdThreshold = 1000000;
        addTotalDemand = 10000000;
        payPercentage = 1500; // 15%
        recommendFee = 1000;
        currentState = State.draft; 
    }


    function timestampToDate(string memory _date) internal pure returns (uint256 timestamp) {
        // Implement date string to timestamp conversion (Simplified example - vulnerable to errors)
        (uint16 year, uint8 month, uint8 day) = splitDate(_date);
        timestamp = uint256((year - 1970) * 31536000 + month * 2592000 + day * 86400); // Approx. conversion
    }

    function splitDate(string memory _date) internal pure returns (uint16 year, uint8 month, uint8 day) {
       bytes memory dateBytes = bytes(_date);
        year = uint16(parseUint(dateBytes, 0, 4));
        month = uint8(parseUint(dateBytes, 5, 2));
        day = uint8(parseUint(dateBytes, 8, 2));
    }

    function parseUint(bytes memory _bytes, uint256 _start, uint256 _len) internal pure returns (uint256 res) {
        for(uint256 i = _start; i < _start + _len; i++) {
            res = res * 10 + uint8(_bytes[i]) - 48; 
        }
    }



    function safeTransfer(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function signAgreement() public {
        require(currentState == State.draft, "Invalid state transition.");
        bool bothSigned = false;

        if (msg.sender == partyA.wallet) {
            partyA.signed = true;
        } else if (msg.sender == partyB.wallet) {
            partyB.signed = true;
        } else {
            revert("Unauthorized party.");
        }

        if (partyA.signed && partyB.signed) {
           executionDate = block.timestamp;
           nextIncomePayDate = executionDate + 30 days;
           nextAdFeeDate = executionDate + 120 days;
           currentState = State.active;
           emit StateTransition(State.draft, State.active);
        }
        emit sign_agreement();

    }

    function renewAgreement(bool renew_approval) public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyA.wallet, "Unauthorized party.");
        require(block.timestamp < endDate, "Agreement already ended.");
        require(renew_approval, "Renewal not approved.");

        isRenewed = true;
        endDate = endDate + renewalPeriod; 
        emit renew_agreement();
    }



    function terminateAgreement() public {
        require(currentState == State.active, "Invalid state transition.");
        require(terminationNoticeDate != 0, "Termination notice date not set.");  // Guard: terminationNoticeDate is not null

        terminationDate = block.timestamp;
        dataOwnership.push(partyA.wallet);
        dataOwnership.push(partyB.wallet);
        currentState = State.terminated;
        emit terminate_agreement();
        emit StateTransition(State.active, State.terminated);
    }


    function breachAdvertisement(bool competitorAdvertisement) public {
        require(currentState == State.active, "Invalid state transition.");
        require(competitorAdvertisement, "No competitor advertisement reported.");

        violatedDate = block.timestamp;
        currentState = State.violated;
        emit breach_advertisement();
        emit StateTransition(State.active, State.violated);

    }

    function transferApproval(bool _writtenApproval) public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        writtenApproval = _writtenApproval; // Assuming input is the intended new value
        emit transfer_approval();
    }


    function transferContract(bool _writtenApproval, bool isCompetitor, address payable transferParty) public {
       require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyA.wallet, "Unauthorized party.");
        require(_writtenApproval, "Written approval required."); 
        require(!isCompetitor, "Transfer to competitor not allowed.");

        transferStatus = true;
        partyA.wallet = transferParty; // Updating the partyA  
        emit transfer_contract();
    }




    function payOnSuccessCandidate(bool recommendCheck) public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        require(recommendCheck, "Recommendation check failed.");

        safeTransfer(partyA.wallet, recommendFee);
        // recommendCheck = false;  Not allowed - it's an input parameter.
        emit pay_on_success_candidate();
    }

    function payIncome(uint256 income) public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        require(block.timestamp > nextIncomePayDate, "Next income payment date not reached.");

        uint256 amountToPay = (income * payPercentage) / 10000; // Correct percentage calculation
        safeTransfer(partyA.wallet, amountToPay);
        incomes.push(income);
        nextIncomePayDate = nextIncomePayDate + 30 days;
        emit pay_income();
    }


    function adFeeRequirements(uint256 adFee) public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        require(block.timestamp > nextAdFeeDate, "Next ad fee payment not due yet.");
        require(adFee > seasonAdThreshold, "Ad fee below threshold.");
        
        safeTransfer(partyA.wallet, adFee); // Transfer the adFee, not income
        addTotalFee += adFee; 
        nextAdFeeDate = nextAdFeeDate + 120 days;
        emit ad_fee_requirements();

    }


    function adFeeViolate() public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        require(block.timestamp > endDate, "Agreement not ended yet.");
        require(addTotalFee < addTotalDemand, "Ad fee demand met.");

        violatedDate = block.timestamp;
        currentState = State.terminated; // Transition to terminated
        emit ad_fee_violate();
        emit StateTransition(State.active, State.terminated);

    }

    function auditProvide(bool auditCheck) public {
        require(currentState == State.active, "Invalid state transition.");
        require(msg.sender == partyB.wallet, "Unauthorized party.");
        require(auditCheck, "Audit check failed.");  // Corrected check condition
        require(block.timestamp <= nextIncomePayDate - 30 days + auditPeriod && block.timestamp >= nextIncomePayDate - 30 days,"Outside the allowed audit provide period.");


        auditProvideDate = block.timestamp;
        emit audit_provide();
    }

    // Helper function to set the termination notice date (can be called by authorized party to initiate termination process). This simplifies the terminateAgreement function.
     function setTerminationNoticeDate() public {
        require(currentState == State.active, "Invalid State");
        terminationNoticeDate = block.timestamp;
     }

}

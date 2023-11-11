/*
 @description Produces a csv file with criteria required for a particular fundraising communication

 CRITERIA:
    Anyone who has given a gift in FYs FY22-24
    AG Staff members who have donated
    Board Members
    ‘Friends & Family’ (this is not yet a made filter or list, but will be a separate request for a checkbox added to contacts and/or accounts)
 
 COLUMNS:
    For each adult in household:
      Contact Id, First Name i, Middle Initial i, Last Name i, Salutation i, Suffix i, Email Address i, Phone i
    Account Id
    Account Name
    MailingStreet
    MailingCity
    MailingState
    MailingPostalCode
    Total Cumulative Giving Amount (all-time)
    Total Cumulative Giving Amount (FY22-24)
    Largest gift amount, allocation, and date (all-time)
    Largest gift amount, allocation, and date (FY22-24)
    Smallest gift amount, allocation, and date (all-time)
    Smallest gift amount, allocation, and date (FY22-24)
*/

String emailSubject = 'Asphalt Green Insider Newsletter recipients';
List<String> lstEmailAddresses = new List<String>{ 'sserkin@asphaltgreen.org' };
String senderDisplayName = 'The AG Data Factory';
String emailBody = 'Attached, please find the requested data.';

Date earliestGiftDate = Date.newInstance(2021, 7, 1);
String emptyCell = ',';

List<String> csvColumnHeaders = new List<String>{
    'Account Id',
    'Account Name',
    'Account Formal Greeting',
    'Account Informal Greeting',
    'Street',
    'City',
    'State',
    'Zip Code',
    'Lifetime Giving Amount',
    'Total Giving Amount (FY22 - FY24)',
    'Largest Gift Amount',
    'Largest Gift Allocation',
    'Largest Gift Date',
    'Smallest Gift Amount',
    'Smallest Gift Allocation',
    'Smallest Gift Date'
};

List<String> csvContactHeaders = new List<String>{
    'Contact Id',
    'Salutation',
    'First Name',
    'Middle Initial',
    'Last Name',
    'Suffix',
    'Email',
    'Phone'
};

/**
 * QUERIES
 */

// All accounts that have given a gift since the beginning of fy22 
List<Account> lstAccs = [
    SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
           BillingStreet, BillingCity, BillingState, BillingPostalCode, 
           (SELECT Id, Amount, StageName, CloseDate, Allocations__c
              FROM Opportunities 
             WHERE Committed__c = true 
             ORDER BY CloseDate ASC),
           (SELECT Id, FirstName, MiddleName, LastName, Salutation, Suffix, Email, Phone
              FROM Contacts
             WHERE TREX1__Age__c >= 18
               AND npsp__Deceased__c = false)
      FROM Account 
     WHERE npo02__LastCloseDate__c > :earliestGiftDate
];

// All board members
/*
List<Contact> lstBoardContacts = [
    SELECT Id, AccountId
      FROM Contact
     WHERE TREX1__Age__c >= 18
       AND npsp__Deceased__c = false
       AND Id IN (SELECT npe5__Contact__c 
                    FROM npe5__Affiliation__c 
                   WHERE npe5__Organization__r.Name LIKE '%Asphalt%' 
                     AND npe5__Role__c LIKE '%Board%'
                     AND npe5__Status__c = 'Current')
];
*/

// All staff contacts that have given a gift
/*
List<Contact> lstStaffContacts = [
    SELECT Id, AccountId
      FROM Contact
     WHERE Contact_Type__c IN ('Full-time Staff','Part-time Staff')
       AND AccountId IN (SELECT AccountId FROM Opportunity WHERE Committed__c = true)
];
*/


/**
 * FILTERING
 */
Map<Id, Account> mapAccounts = new Map<Id, Account>();
Map<Id, List<String>> mapInclusionReasons = new Map<Id, List<String>>();
Map<Id, Opportunity> mapLargestOpp = new Map<Id, Opportunity>();
Map<Id, Opportunity> mapSmallestOpp = new Map<Id, Opportunity>();
Map<Id, Decimal> mapQualifyingFyGiftAmount = new Map<Id, Decimal>();
Integer maxContacts = 0;

for (Account acc : lstAccs) {
    if (!mapInclusionReasons.containsKey(acc.Id)) {
        mapInclusionReasons.put(acc.Id, new List<String>());
    }
    if (acc.Contacts.size() > maxContacts) {
        maxContacts = acc.Contacts.size();
    }

    Decimal giftTotal = 0.00;
    Decimal qualifyingFyGiftTotal = 0.00;
    Decimal largestOppAmount;
    Decimal smallestOppAmount;
    Decimal largestQualifyingFyOppAmount;
    Decimal smallestQualifyingFyOppAmount;
    // Map<String, Decimal> mapFyTotals = new Map<String, Decimal>();
    // Set<String> setQualifyingFys = new Set<String>();
    Boolean addToMap = false;

    for (Opportunity opp : acc.Opportunities) {
        giftTotal += opp.Amount;
        // Check for fiscal year to add to qualifying fy total
        if (opp.CloseDate >= earliestGiftDate) {
            qualifyingFyGiftTotal += opp.Amount;
        }
        // Check against largest gift so far
        if (largestOppAmount == null || opp.Amount > largestOppAmount) {
            largestOppAmount = opp.Amount;
            mapLargestOpp.put(acc.Id, opp);
        }
        // Check against smallest gift so far
        if (smallestOppAmount == null || opp.Amount < smallestOppAmount) {
            smallestOppAmount = opp.Amount;
            mapSmallestOpp.put(acc.Id, opp);
        }
        /*
        String fy = opp.CloseDate.month() >= 7 
            ? String.valueOf( opp.CloseDate.year() + 1 ).right(2)
            : String.valueOf( opp.CloseDate.year() ).right(2);
        if (!mapFyTotals.containsKey(fy)) {
            mapFyTotals.put(fy, 0.00);
        }
        mapFyTotals.put(fy, mapFyTotals.get(fy) + opp.Amount);

        if (mapFyTotals.get(fy) > 1000) {
            setQualifyingFys.add('FY' + fy);
        }
        */
    }

    mapAccounts.put(acc.Id, acc);
    mapQualifyingFyGiftAmount.put(acc.Id, qualifyingFyGiftTotal);

/*
    if (!setQualifyingFys.isEmpty()) {
        addToMap = true;
        List<String> lstFys = new List<String>();
        lstFys.addAll(setQualifyingFys);
        List<String> lstReasons = mapInclusionReasons.get(acc.Id);
        lstReasons.add('Gifts over $1k in ' + String.join(lstFys, ', '));
        mapInclusionReasons.put(
            acc.Id, 
            lstReasons
        );
    }

    if (giftTotal >= 5000) {
        addToMap = true;
        List<String> lstReasons = mapInclusionReasons.get(acc.Id);
        lstReasons.add('Total gifts over $5k since FY19');
        mapInclusionReasons.put(
            acc.Id, 
            lstReasons
        );
    }

    if (addToMap) {
        mapAccounts.put(acc.Id, acc);
    }
    */
}

// Filter out duplicate board member accounts by adding to account map
/*
Set<Id> setIdsToQuery = new Set<Id>();
for (Contact bc : lstBoardContacts) {
    setIdsToQuery.add(bc.AccountId);
    if (!mapInclusionReasons.containsKey(bc.AccountId)) {
        mapInclusionReasons.put(bc.AccountId, new List<String>());
    }
    List<String> lstReasons = mapInclusionReasons.get(bc.AccountId);
    lstReasons.add('Board member');
    mapInclusionReasons.put(
        bc.AccountId, 
        lstReasons
    );
}
*/

// Filter out duplicate staff member accounts by adding to account map
/*
for (Contact sc : lstStaffContacts) {
    setIdsToQuery.add(sc.AccountId);
    if (!mapInclusionReasons.containsKey(sc.AccountId)) {
        mapInclusionReasons.put(sc.AccountId, new List<String>());
    }
    List<String> lstReasons = mapInclusionReasons.get(sc.AccountId);
    lstReasons.add('Staff member');
    mapInclusionReasons.put(
        sc.AccountId, 
        lstReasons
    );
}
*/

// Re-query for all adults in households of board members and staff members
// that are not already in the map
/*
List<Account> lstFamilies = [
    SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
           BillingStreet, BillingCity, BillingState, BillingPostalCode, 
           (SELECT Id, FirstName, MiddleName, LastName, Salutation, Suffix, Email
              FROM Contacts
             WHERE TREX1__Age__c >= 18)
      FROM Account 
     WHERE Id IN :setIdsToQuery
];
for (Account fam : lstFamilies) {
    if (fam.Contacts.size() > maxContacts) {
        maxContacts = fam.Contacts.size();
    }
    mapAccounts.put(fam.Id, fam);
}
*/

/**
 * CONSTRUCT CSV
 */
String csvString = '';
// Headers
for (String col : csvColumnHeaders) {
    csvString += col + ',';
}
for (Integer i = 0; i < maxContacts; i++) {
    for (Integer n = 0; n < csvContactHeaders.size(); n++) {
        csvString += csvContactHeaders[n] + ' ' + String.valueOf(i + 1);
        if (n < csvContactHeaders.size() - 1) csvString += ',';
    }
    if (i < maxContacts - 1) csvString += ',';
}
csvString += '\n';

/*
    'Account Id',
    'Account Name',
    'Account Formal Greeting',
    'Account Informal Greeting',
    'Street',
    'City',
    'State',
    'Zip Code',
    'Lifetime Giving Amount',
    'Total Giving Amount FY22 - FY24',
    'Largest Gift Amount',
    'Largest Gift Allocation',
    'Largest Gift Date',
    'Smallest Gift Amount',
    'Smallest Gift Allocation',
    'Smallest Gift Date'
*/
// Add accounts to csv
Integer rowCount = 0;
for (Account curAcc : mapAccounts.values()) {
    csvString += curAcc.Id + ',';

    csvString += '"' + curAcc.Name + '",';

    if (!String.isBlank(curAcc.npo02__Formal_Greeting__c)) {
        csvString += '"' + curAcc.npo02__Formal_Greeting__c.replaceAll('"','""') + '",';
    } else {
        csvString += emptyCell;
    }

    if (!String.isBlank(curAcc.npo02__Informal_Greeting__c)) {
        csvString += '"' + curAcc.npo02__Informal_Greeting__c.replaceAll('"','""') + '",';
    } else {
        csvString += emptyCell;
    }

    if (!String.isBlank(curAcc.BillingStreet)) {
        csvString += '"' + curAcc.BillingStreet.replaceAll('"','""').replaceAll('\n', ' ').replaceAll('\r', '') + '",';
    } else {
        csvString += emptyCell;
    }

    if (!String.isBlank(curAcc.BillingCity)) {
        csvString += curAcc.BillingCity + ',';
    } else {
        csvString += emptyCell;
    }

    if (!String.isBlank(curAcc.BillingState)) {
        csvString += curAcc.BillingState + ',';
    } else {
        csvString += emptyCell;
    }

    if (!String.isBlank(curAcc.BillingPostalCode)) {
        csvString += curAcc.BillingPostalCode + ',';
    } else {
        csvString += emptyCell;
    }

    csvString += '$' + String.valueOf(curAcc.npo02__TotalOppAmount__c) + ',';

    csvString += '$' + String.valueOf(mapQualifyingFyGiftAmount.get(curAcc.Id)) + ',';

    // Largest gift
    Opportunity bigOpp = mapLargestOpp.get(curAcc.Id);
    csvString += '$' + String.valueOf(bigOpp.Amount) + ',' + bigOpp.Allocations__c + ',' + bigOpp.CloseDate.format() + ',';

    // Smallest gift
    Opportunity littleOpp = mapSmallestOpp.get(curAcc.Id);
    csvString += '$' + String.valueOf(littleOpp.Amount) + ',' + littleOpp.Allocations__c + ',' + littleOpp.CloseDate.format() + ',';

    // csvString += '"' + String.join(mapInclusionReasons.get(curAcc.Id), '; ') + '",';

    /*
        'Contact Id',
        'Salutation'
        'First Name',
        'Middle Initial',
        'Last Name',
        'Suffix',
        'Email',
        'Phone'
    */
    for (Contact accCt : curAcc.Contacts) {
        csvString += accCt.Id + ',';
        csvString += accCt.Salutation != null ? accCt.Salutation + ',' : emptyCell;
        csvString += accCt.FirstName != null ? accCt.FirstName + ',' : emptyCell;
        csvString += accCt.MiddleName != null ? accCt.MiddleName.left(1) + '.' + ',' : emptyCell;
        csvString += accCt.LastName != null ? accCt.LastName + ',' : emptyCell;
        csvString += accCt.Suffix != null ? accCt.Suffix + ',' : emptyCell;
        csvString += accCt.Email != null ? accCt.Email + ',' : emptyCell;
        csvString += accCt.Phone != null ? accCt.Phone + ',' : emptyCell;
    }

    if (maxContacts > curAcc.Contacts.size()) {
        Integer numEmptyRows = (maxContacts - curAcc.Contacts.size());
        csvString += emptyCell.repeat(8 * numEmptyRows);
    }

    rowCount++;
    if (rowCount < mapAccounts.size()) {
        csvString += '\n';
    }
}

/**
 * BUILD EMAIL AND SEND
 */
// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('Asphalt_Green_Insiders.csv');
attachment.setBody(Blob.valueOf(csvString));

// Create email with attachment
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(lstEmailAddresses);
email.setSubject(emailSubject);
email.setSenderDisplayName(senderDisplayName);
email.setPlainTextBody(emailBody);
email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ 
    attachment 
});

// Send email
Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{ email } );


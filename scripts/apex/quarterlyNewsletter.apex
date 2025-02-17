/*
 @description Produces a csv file with criteria required for a particular fundraising communication

 CRITERIA:
    Anyone who has given a gift in FYs FY22-24
 
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
    Smallest gift amount, allocation, and date (all-time)
*/

String emailSubject = 'Asphalt Green Insider Newsletter recipients';
List<String> lstEmailAddresses = new List<String>{ 'sserkin@asphaltgreen.org' };
String senderDisplayName = 'The AG Data Factory';
String emailBody = 'Attached, please find the requested data.';
String csvFileName = 'Asphalt_Green_Insiders.csv';

Date earliestGiftDate = Date.newInstance(2021, 1, 1);
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
    'Total Giving Amount (CY21 - CY23)',
    'Total CY23',
    'Total CY22',
    'Total CY21',
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

Id hhRecTypId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();

/**
 * QUERIES
 */

// All accounts that have given a gift since the beginning of cy21 
List<Account> lstAccs = [
    SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
           BillingStreet, BillingCity, BillingState, BillingPostalCode, 
           (SELECT Id, Amount, StageName, CloseDate, Allocations__c, CampaignId, Campaign.Name
              FROM Opportunities 
             WHERE Committed__c = true 
             ORDER BY CloseDate DESC),
           (SELECT Id, FirstName, MiddleName, LastName, Salutation, Suffix, Email, Phone
              FROM Contacts
             WHERE TREX1__Age__c >= 18
               AND npsp__Deceased__c = false)
      FROM Account 
     WHERE npo02__LastCloseDate__c > :earliestGiftDate
       AND npo02__TotalOppAmount__c > 1000
       AND RecordTypeId = :hhRecTypId
];

/**
 * FILTERING
 */
Map<Id, Account> mapAccounts = new Map<Id, Account>();
Map<Id, Opportunity> mapLargestOpp = new Map<Id, Opportunity>();
Map<Id, Opportunity> mapSmallestOpp = new Map<Id, Opportunity>();
Map<Id, Decimal> mapQualifyingFyGiftAmount = new Map<Id, Decimal>();
Map<Id, Map<Integer, Decimal>> mapFyGiving = new Map<Id, Map<Integer, Decimal>>();
Integer maxContacts = 0;

for (Account acc : lstAccs) {
    // Set largest number of contacts size to determine number of columns
    if (acc.Contacts.size() > maxContacts) {
        maxContacts = acc.Contacts.size();
    }

    // Track totals for account
    Decimal giftTotal = 0.00;
    Decimal qualifyingFyGiftTotal = 0.00;
    Decimal largestOppAmount;
    Date largestOppCloseDate;
    Decimal smallestOppAmount;
    Decimal largestQualifyingFyOppAmount;
    Decimal smallestQualifyingFyOppAmount;
    Map<Integer, Decimal> mapFyTotals = new Map<Integer, Decimal>();
    Decimal cy23 = 0.00;
    Decimal cy22 = 0.00;
    Decimal cy21 = 0.00;

    for (Opportunity opp : acc.Opportunities) {
        giftTotal += opp.Amount;
        // Check for fiscal year to add to qualifying fy total
        if (opp.CloseDate >= earliestGiftDate) {
            qualifyingFyGiftTotal += opp.Amount;
            if (opp.CloseDate < Date.newInstance(2021,1,1)) {
                // do nothing here
            } else if (opp.CloseDate < Date.newInstance(2022,1,1)) {
                cy21 += opp.Amount;
            } else if (opp.CloseDate < Date.newInstance(2023,1,1)) {
                cy22 += opp.Amount;
            } else {
                cy23 += opp.Amount;
            }
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
    }

    // Verify qualification for list
    if (cy21 >= 1000 || cy22 >= 1000 || cy23 > 1000) {
        mapFyTotals.put(23, cy23);
        mapFyTotals.put(22, cy22);
        mapFyTotals.put(21, cy21);

        mapFyGiving.put(acc.Id, mapFyTotals);

        mapAccounts.put(acc.Id, acc);
        mapQualifyingFyGiftAmount.put(acc.Id, qualifyingFyGiftTotal);
    }
}


/**
 * CONSTRUCT CSV
 */
String csvString = '';
// Account headers
for (String col : csvColumnHeaders) {
    csvString += col + ',';
}
// Contact headers
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

    // Cumulative giving totals for all-time and qualifying fiscal years
    csvString += '$' + String.valueOf(curAcc.npo02__TotalOppAmount__c) + ',';
    csvString += '$' + String.valueOf(mapQualifyingFyGiftAmount.get(curAcc.Id)) + ',';

    // Individual fiscal year totals
    Map<Integer, Decimal> mapCyTotals = mapFyGiving.get(curAcc.Id);
    csvString += '$' + String.valueOf( mapCyTotals.get(23) ) + ',';
    csvString += '$' + String.valueOf( mapCyTotals.get(22) ) + ',';
    csvString += '$' + String.valueOf( mapCyTotals.get(21) ) + ',';

    // Largest gift
    Opportunity bigOpp = mapLargestOpp.get(curAcc.Id);
    csvString += '$' + String.valueOf(bigOpp.Amount) + ',';
    if (bigOpp.Allocations__c != null) {
        csvString += bigOpp.Allocations__c + ',';
    } else if (bigOpp.CampaignId != null) {
        csvString += bigOpp.Campaign.Name + ',';
    } else {
        csvString += emptyCell;
    }
    csvString += bigOpp.CloseDate.format() + ',';

    // Smallest gift
    Opportunity littleOpp = mapSmallestOpp.get(curAcc.Id);
    csvString += '$' + String.valueOf(littleOpp.Amount) + ',';
    if (littleOpp.Allocations__c != null) {
        csvString += littleOpp.Allocations__c + ',';
    } else if (littleOpp.CampaignId != null) {
        csvString += littleOpp.Campaign.Name + ',';
    } else {
        csvString += emptyCell;
    }
    csvString += littleOpp.CloseDate.format() + ',';
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
attachment.setFileName(csvFileName);
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


/*
 @description Produces a csv file with criteria required for a particular fundraising communication

 CRITERIA:
    Board members
    Any gift to BSBK or Gala since FY19
    Largest lifetime gift amount >= 10000 (including organizations)
    Accumulative $1k last 5 years
 
 COLUMNS:
    For each adult in household:
      Contact Id, 
      Salutation i, 
      First Name i, 
      Middle Initial i, 
      Last Name i, 
      Email Address i, 
      Alternate Email Address i, 
      Phone i
    Account Id
    Account Name
    Formal Greeting
    Informal Greeting
    MailingStreet
    MailingCity
    MailingState
    MailingPostalCode
*/

String emailSubject = 'Gala Invitation Recipients';
List<String> lstEmailAddresses = new List<String>{ 'sserkin@asphaltgreen.org' };
String senderDisplayName = 'The AG Data Factory';
String emailBody = 'Attached, please find the requested data.';
String csvFileName = 'Gala_Invitation_Recipients.csv';

Date earliestGiftDate = Date.newInstance(2021, 1, 1);
Date minCampaignStartDate = Date.newInstance(2018, 7, 1);
String emptyCell = ',';

List<String> csvAccountHeaders = new List<String>{
    'Account Id',
    'Account Name',
    'Inclusion Reasons',
    'Account Formal Greeting',
    'Account Informal Greeting',
    'Street',
    'City',
    'State',
    'Zip Code'
};

List<String> csvContactHeaders = new List<String>{
    'Contact Id',
    'Salutation',
    'First Name',
    'Middle Initial',
    'Last Name',
    'Personal Email',
    'Alternate Email',
    'Mobile Phone', // MobilePhone
    'Home Phone', // HomePhone
    'Work Phone' // npe01__WorkPhone__c
};

Id hhRecTypId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();

Map<Id, List<String>> mapInclusionReasons = new Map<Id, List<String>>();

/**
 * QUERIES
 */

Set<Id> setAccIds = new Set<Id>();

// Get board members' account ids
List<npe5__Affiliation__c> lstBoardMemberAffs = [
    SELECT npe5__Contact__r.AccountId 
      FROM npe5__Affiliation__c 
     WHERE npe5__Organization__r.Name = 'Asphalt Green' 
       AND npe5__Status__c = 'Current' 
       AND npe5__Role__c LIKE '%Board%'
];
for (npe5__Affiliation__c aff : lstBoardMemberAffs) {
    setAccIds.add(aff.npe5__Contact__r.AccountId);
    mapInclusionReasons.put(aff.npe5__Contact__r.AccountId, new List<String>{'Board Member'});
}

// Get accs meeting appeal criteria
List<Account> lstAppealAccs = [
    SELECT Id
      FROM Account 
     WHERE Id IN (SELECT AccountId
                    FROM Opportunity
                   WHERE (Campaign.Name like '%BSBK%' OR Campaign.Name like '%Gala%')
                     AND Campaign.StartDate >= :minCampaignStartDate)
       AND RecordTypeId = :hhRecTypId
];
for (Account acc : lstAppealAccs) {
    setAccIds.add(acc.Id);
    String strReason = 'Previous Gala Supporter';
    if (mapInclusionReasons.containsKey(acc.Id)) {
        List<String> lstReasons = mapInclusionReasons.get(acc.Id);
        lstReasons.add(strReason);
        mapInclusionReasons.put(acc.Id, lstReasons);
    } else {
        mapInclusionReasons.put(acc.Id, new List<String>{strReason});
    }
}

// Get accs meeting largest gift criteria
List<Account> lstGiftAccs = [
    SELECT Id
      FROM Account 
     WHERE npo02__LargestAmount__c >= 10000
];
for (Account acc : lstGiftAccs) {
    setAccIds.add(acc.Id);
    String strReason = 'Gift over $10k';
    if (mapInclusionReasons.containsKey(acc.Id)) {
        List<String> lstReasons = mapInclusionReasons.get(acc.Id);
        lstReasons.add(strReason);
        mapInclusionReasons.put(acc.Id, lstReasons);
    } else {
        mapInclusionReasons.put(acc.Id, new List<String>{strReason});
    }
}

// Get accs meeting 5 year gift criteria
List<Account> lstYearsAccs = [
    SELECT Id, 
           (SELECT Amount FROM Opportunities WHERE CloseDate >= 2019-01-01)
      FROM Account 
     WHERE Id IN (SELECT AccountId 
                    FROM Opportunity
                   WHERE CloseDate >= 2019-01-01 AND Committed__c = true)
];
for (Account acc : lstYearsAccs) {
    Decimal totalAmount = 0.00;
    for (Opportunity opp : acc.Opportunities) {
        totalAmount += opp.Amount != null ? opp.Amount : 0;
    }
    if (totalAmount >= 1000) setAccIds.add(acc.Id);

    String strReason = 'Gift over $1k - last 5 years';
    if (mapInclusionReasons.containsKey(acc.Id)) {
        List<String> lstReasons = mapInclusionReasons.get(acc.Id);
        lstReasons.add(strReason);
        mapInclusionReasons.put(acc.Id, lstReasons);
    } else {
        mapInclusionReasons.put(acc.Id, new List<String>{strReason});
    }
}

// Get account and contact data
List<Account> lstAccs = [
    SELECT Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
           BillingStreet, BillingCity, BillingState, BillingPostalCode, 
           (SELECT Id, FirstName, MiddleName, LastName, npe01__HomeEmail__c, npe01__AlternateEmail__c, 
                   MobilePhone, npe01__WorkPhone__c, HomePhone, Salutation
              FROM Contacts
             WHERE TREX1__Age__c >= 18
               AND npsp__Deceased__c = false
             ORDER BY TREX1__Age__c DESC)
      FROM Account 
     WHERE Id IN :setAccIds
];


/**
 * CONSTRUCT CSV
 */
String csvString = '';
Integer maxContacts = 0;

for (Account acc : lstAccs) {
    if (acc.Contacts.size() > maxContacts) {
        maxContacts = acc.Contacts.size();
    }
}

for (String col : csvAccountHeaders) {
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
List<String> csvAccountHeaders = new List<String>{
    'Account Id',
    'Account Name',
    'Account Formal Greeting',
    'Account Informal Greeting',
    'Street',
    'City',
    'State',
    'Zip Code'
};
*/

// Add accounts to csv
Integer rowCount = 0;
for (Account curAcc : lstAccs) {
    csvString += curAcc.Id + ',';

    csvString += '"' + curAcc.Name + '",';

    if (mapInclusionReasons.containsKey(curAcc.Id)) {
        csvString += String.join(mapInclusionReasons.get(curAcc.Id), '; ') + ',';
    } else {
        csvString += ',';
    }

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

    for (Contact accCt : curAcc.Contacts) {
        csvString += accCt.Id + ',';
        csvString += accCt.Salutation != null ? accCt.Salutation + ',' : emptyCell;
        csvString += accCt.FirstName != null ? accCt.FirstName + ',' : emptyCell;
        csvString += accCt.MiddleName != null ? accCt.MiddleName.left(1) + ',' : emptyCell;
        csvString += accCt.LastName != null ? accCt.LastName + ',' : emptyCell;
        csvString += accCt.npe01__HomeEmail__c != null ? accCt.npe01__HomeEmail__c + ',' : emptyCell;
        csvString += accCt.npe01__AlternateEmail__c != null ? accCt.npe01__AlternateEmail__c + ',' : emptyCell;
        csvString += accCt.MobilePhone != null ? accCt.MobilePhone + ',' : emptyCell;
        csvString += accCt.HomePhone != null ? accCt.HomePhone + ',' : emptyCell;
        csvString += accCt.npe01__WorkPhone__c != null ? accCt.npe01__WorkPhone__c + ',' : emptyCell;
    }

    if (maxContacts > curAcc.Contacts.size()) {
        Integer numEmptyRows = (maxContacts - curAcc.Contacts.size());
        csvString += emptyCell.repeat(10 * numEmptyRows);
    }

    rowCount++;
    if (rowCount < lstAccs.size()) {
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


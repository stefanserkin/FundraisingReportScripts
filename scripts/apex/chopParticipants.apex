/*
 @description Produces a csv file with criteria required for a particular fundraising communication

 CRITERIA:
    - Currently enrolled in one or more youth programs of all types, including rec sports and competitive/travel teams
    - Please include Members AND non-members who meet the above criteria (b.1.)
    - Of these names, please set a threshold of having made one or more gifts of $500 or more at any time.
 
 COLUMNS:
    For each adult in household:
      Contact Id, First Name i, Middle Initial i, Last Name i, Salutation i, Suffix i, Email Address i, Phone i
    Account Id
    Account Name
    MailingStreet
    MailingCity
    MailingState
    MailingPostalCode
*/

String emailSubject = 'CHOP Priority Recipients';
List<String> lstEmailAddresses = new List<String>{ 'sserkin@asphaltgreen.org' };
String senderDisplayName = 'The AG Data Factory';
String emailBody = 'Attached, please find the requested data.';
String csvFileName = 'CHOP_Priority_Recipients.csv';

String emptyCell = ',';

List<String> csvAccountHeaders = new List<String>{
    'Account Id',
    'Account Name',
    'Account Formal Greeting',
    'Account Informal Greeting',
    'Street',
    'City',
    'State',
    'Zip Code',
    'Household Total Cumulative Giving', 
    'Household Largest Gift Amount',
    'Household Largest Gift Date',
    'Household Largest Gift Fund/Purpose',
    'Memberships',
    'Registrations'
};

List<String> csvContactHeaders = new List<String>{
    'Contact Id',
    'First Name',
    'Last Name',
    'Personal Email',
    'Alternate Email',
    'Mobile Phone',
    'Work Phone'
};

Id hhRecTypId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();

/**
 * QUERIES
 */

Set<Id> setAccIds = new Set<Id>();

// Get account ids
List<TREX1__Registration__c> lstRegs = [
    SELECT Id, TREX1__Contact__r.AccountId 
      FROM TREX1__Registration__c 
     WHERE TREX1__Registration_Status__c IN ('Active','Pending Active') 
       AND Qualifying_Enrollments__c > 0
       AND TREX1__Contact__r.TREX1__Age__c < 18
       AND TREX1__Account__r.npo02__TotalOppAmount__c > 500
];
for (TREX1__Registration__c reg : lstRegs) {
    setAccIds.add(reg.TREX1__Contact__r.AccountId);
}

// Get account and contact data
List<Account> lstAccs = [
    SELECT Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
           BillingStreet, BillingCity, BillingState, BillingPostalCode, npo02__TotalOppAmount__c,
           (SELECT Id, FirstName, LastName, npe01__HomeEmail__c, npe01__AlternateEmail__c, 
                   MobilePhone, npe01__WorkPhone__c
              FROM Contacts
             WHERE TREX1__Age__c >= 18
               AND npsp__Deceased__c = false
             ORDER BY TREX1__Age__c DESC),
           (SELECT CloseDate, Amount, Allocations__c, Campaign.Name
              FROM Opportunities
             ORDER BY Amount DESC),
           (SELECT TREX1__Contact__r.FirstName, TREX1__Program_Name__c
              FROM TREX1__Registrations__r
             WHERE TREX1__Registration_Status__c IN ('Active','Pending Active') 
               AND Qualifying_Enrollments__c > 0),
           (SELECT TREX1__Contact__r.FirstName, Type_of_Membership__c
              FROM TREX1__Memberships__r
             WHERE TREX1__Category_Name__c IN ('Individual Memberships','Family Memberships') 
               AND TREX1__Status__c IN ('Active','Pending Transfer','On Hold','Pending Cancellation'))
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

// Add accounts to csv
Integer rowCount = 0;
for (Account curAcc : lstAccs) {
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

    csvString += '$' + String.valueOf( curAcc.npo02__TotalOppAmount__c ) + ',';

    Opportunity opp = curAcc.Opportunities[0];
    csvString += opp.CloseDate + ',' + '$' + String.valueOf( opp.Amount ) + ',';
    csvString += opp.Allocations__c != null ? opp.Allocations__c : opp.Campaign.Name;
    csvString += ',';

    List<String> memStrings = new List<String>();
    for (TREX1__Membership__c mem : curAcc.TREX1__Memberships__r) {
        String s = mem.Type_of_Membership__c + ' (' + mem.TREX1__Contact__r.FirstName + ')';
        if (!memStrings.contains(s)) {
            memStrings.add(s);
        }
    }
    csvString += String.join(memStrings, '; ') + ',';

    List<String> regStrings = new List<String>();
    for (TREX1__Registration__c reg : curAcc.TREX1__Registrations__r) {
        String s = reg.TREX1__Program_Name__c + ' (' + reg.TREX1__Contact__r.FirstName + ')';
        if (!regStrings.contains(s)) {
            regStrings.add(s);
        }
    }
    csvString += String.join(regStrings, '; ') + ',';

    for (Contact accCt : curAcc.Contacts) {
        csvString += accCt.Id + ',';
        csvString += accCt.FirstName != null ? accCt.FirstName + ',' : emptyCell;
        csvString += accCt.LastName != null ? accCt.LastName + ',' : emptyCell;
        csvString += accCt.npe01__HomeEmail__c != null ? accCt.npe01__HomeEmail__c + ',' : emptyCell;
        csvString += accCt.npe01__AlternateEmail__c != null ? accCt.npe01__AlternateEmail__c + ',' : emptyCell;
        csvString += accCt.MobilePhone != null ? accCt.MobilePhone + ',' : emptyCell;
        csvString += accCt.npe01__WorkPhone__c != null ? accCt.npe01__WorkPhone__c + ',' : emptyCell;
    }

    if (maxContacts > curAcc.Contacts.size()) {
        Integer numEmptyRows = (maxContacts - curAcc.Contacts.size());
        csvString += emptyCell.repeat(7 * numEmptyRows);
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


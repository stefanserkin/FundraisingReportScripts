
String emailSubject = 'Gala Invitation Recipients';
List<String> lstEmailAddresses = new List<String>{ 'sserkin@asphaltgreen.org' };
String senderDisplayName = 'The AG Data Factory';
String emailBody = 'Attached, please find the requested data.';
String csvFileName = 'Gala_Invitation_Recipients.csv';

String emptyCell = ',';

List<String> csvAccountHeaders = new List<String>{
    'Account Id',
    'Account Name',
    // 'Inclusion Reasons',
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
     WHERE Include_in_Wealth_Screening__c = true
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

/*
    if (mapInclusionReasons.containsKey(curAcc.Id)) {
        csvString += String.join(mapInclusionReasons.get(curAcc.Id), '; ') + ',';
    } else {
        csvString += ',';
    }
    */

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
        csvString += emptyCell.repeat(9 * numEmptyRows);
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

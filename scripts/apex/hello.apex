// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

String str = 'Id, AccountId, AG_ID__c, Salutation, FirstName, MiddleName, LastName, Suffix, ' +
           'MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode,  ' +
           'Account.npo02__TotalOppAmount__c, Account.npo02__NumberOfClosedOpps__c, Account.npo02__LastOppAmount__c,  ' +
           'Account.npo02__LastCloseDate__c, Account.npo02__Best_Gift_Year_Total__c, Account.npo02__Best_Gift_Year__c,  ' +
           'Birthdate, TREX1__Age__c, MobilePhone, HomePhone, npe01__WorkPhone__c, OtherPhone';

String newstr = str.replace(' ', '');

List<String> lstStrings = newstr.split(',');

String finalString = String.join(lstStrings, ' + \',\' + ct.');
System.debug(finalString);
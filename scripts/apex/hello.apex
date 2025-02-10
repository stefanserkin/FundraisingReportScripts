// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

Contact[] lstContacts = [select Id, MailingStreet, Include_in_Wealth_Screening__c from Contact where Include_in_Wealth_Screening__c = true and MailingStreet = ''];
for (Contact ct : lstContacts) ct.Include_in_Wealth_Screening__c = false;
update lstContacts;

Date fakeBirthday = Date.newInstance(1945, 1, 1);
Date minDate = Date.newInstance(2023, 12, 7);
Datetime minDatetime = Datetime.newInstance(mindDate, Time.newInstance(0, 0, 0, 0));
// CreatedDate >= 2023-12-07T00:00:00.000-05:00 

Set<Id> setContactIds = new Set<Id>();
Set<Id> setAccountIds = new Set<Id>();

List<Contact> lstRegCts = [
    SELECT Id, AccountId 
      FROM Contact
     WHERE CreatedDate >= :minDatetime
       AND Account.BillingStreet != null
       AND TREX1__Age__c >= 18
       AND Birthdate != :fakeBirthday
       AND AccountId IN (SELECT TREX1__Account__c 
                           FROM TREX1__Registration__c 
                          WHERE TREX1__Start_Date__c >= :minDate
                            AND Qualifying_Enrollments__c > 0)
];

List<Contact> lstMemCts = [
    SELECT Id, AccountId 
      FROM Contact
     WHERE CreatedDate >= :minDatetime
       AND Account.BillingStreet != null
       AND TREX1__Age__c >= 18
       AND AccountId IN (SELECT TREX1__Account__c 
                           FROM TREX1__Membership__c 
                          WHERE TREX1__Status__c in ('Active', 'Complete', 'Pending Active', 'Pending Cancel', 'Pending Transfer', 'On Hold')
                            AND TREX1__Start_Date__c >= :minDate)
];

List<Contact> lstOppCts = [
    SELECT Id, AccountId
      FROM Contact
     WHERE CreatedDate >= :minDatetime
       AND AccountId IN (SELECT AccountId 
                         FROM Opportunity 
                        WHERE CloseDate >= :minDate)
];


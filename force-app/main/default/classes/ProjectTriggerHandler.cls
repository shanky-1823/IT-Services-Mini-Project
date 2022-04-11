public with sharing class ProjectTriggerHandler {
    //Create Project Assignment
    public static void createProjectAssignment(List<Project__c> projList) {
        
        //Create a list of employees who are in the status of unassigned
        List<Employee__c> empList = [SELECT Id, Name, Employee_Id__c, Employee_Status__c 
                                     FROM Employee__c WHERE Employee_Status__c != 'Assigned'];
        System.debug('Employees with unassigned status: '+empList);
        
        
        if(projList[0].Project_Stage__c == 'Draft'){
            //Flag variable to store the assigned employees count
            Integer empAssigned=0;
            System.debug('Project List recId: '+projList[0].Id);
            //List of Project Assignments
            List<Project_Assignment__c> projAssgList = new List<Project_Assignment__c>();
            for(Employee__c emp:empList){
                if(empAssigned<projList[0].Required_Resources__c){
                    System.debug('Employees Assigned: '+empAssigned);
                    //Create project assignment
                    Project_Assignment__c newProjAssg = new Project_Assignment__c();
                    newProjAssg.Project__c = projList[0].Id;
                    newProjAssg.Project_Start_Date__c = projList[0].Project_Start_Date__c;
                    newProjAssg.Roll_off_Date__c = projList[0].Project_End_Date__c;
                    newProjAssg.Employee__c = emp.Id;
                    empAssigned++;
                    //Add the record instance to list
                    projAssgList.add(newProjAssg);
                    System.debug('Project Assignment List to be inserted: '+projAssgList);
                    //insert projAssgList;
                    System.debug('No.of employees assigned till now: '+empAssigned);
                }
            }
            insert projAssgList;
        }
        
    }
    
    //Send email to the employees for whom the project has been finished
    public static void sendEmail(List<Project__c> projList){
        if(projList[0].Project_Stage__c=='Canceled' || projList[0].Project_Stage__c=='Delivered'){
            System.debug('Condition passed');
            //Query on Project Assignment record to find the project that has been Delivered/Canceled, from which Employees can be fetched
            List<Project_Assignment__c> projAssgList =[SELECT Id,Name,Project__c,Employee__c 
                                                       FROM Project_Assignment__c WHERE Project__c=:projList[0].Id];
            //List of employees who are assigned to the particular project
            List<Employee__c> assignedEmpList = new List<Employee__c>();
            //Collect the Employee ids to whom the email needs to be sent
            List<Id> empIds = new List<Id>();
            for(Project_Assignment__c pa:projAssgList){
                empIds.add(pa.Employee__c);
            }
            assignedEmpList = [SELECT Id, Name, Employee_Status__c, Email__c
                               FROM Employee__c WHERE Id IN:empIds];
            //Send email method
            for(Employee__c emp:assignedEmpList){
                List<String> emailIds = new List<String>();
                List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
                emailIds.add(emp.Email__c);
                System.debug('Emails ids to which the message is to be sent: '+emailIds);  
                //Emailing logic
                if(emp.Email__c!=null){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setSenderDisplayName('System Administrator');
                    mail.setSubject('Aces Project Management: Project Update');
                    String body = 'Dear '+emp.Name+', <br/>';
                    body+='The project that you were assigned is finished.<br/><br/>';
                    body+='Thank you!';
                    mail.setHtmlBody(body);
                    mail.toAddresses = new String[]{emp.Email__c};
                    emailList.add(mail);
                    system.debug('Email: '+emailList);
                }
                //Error tracking logic
                if(emailList.size()>0){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
                    if(results[0].success){
                        System.debug('The email was sent successfully');
                    }
                    else{
                        System.debug('The email failed to send: '+ results[0].errors[0].message);
                    }
                } 
                
            }
        }
    }
}
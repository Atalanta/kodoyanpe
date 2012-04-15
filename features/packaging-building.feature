Feature: Building a package
  
  So that I can provide Solaris customers with the fruits of our labour,
  As a member of the Opscode Engineering team,
  I can build a self-contained "Chef Full" package

Background:
  Given a copy of the kodoyanpe tool
  
  Scenario: Get help
    When I run the command without options
    Then I see some help text


  Scenario: Build Solaris 10 SPARC Package
    When I run the command
    And I specify "sparc" as the architecture
    And I specify "5.10" as the version
    Then I should get a package of the latest Chef client accessible from my workstation
    

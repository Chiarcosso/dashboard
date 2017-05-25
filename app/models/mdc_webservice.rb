class SessionID

  def initialize(id)
    @id = id
  end

  def id
    @id
  end

  def xml
    "<ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.id}</ns1:sessionID>"
  end
end

class DataCollectionHead
  def initialize(applicationCode, applicationID, collectionID, deviceCode)
    @applicationCode = applicationCode
    @applicationID = applicationID
    @collectionID = collectionID
    @deviceCode = deviceCode
  end

  def applicationCode
    @applicationCode
  end

  def applicationID
    @applicationID
  end

  def collectionID
    @collectionID
  end

  def deviceCode
    @deviceCode
  end

  def xml
    "<ns3:dataCollectionHead xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"><ns1:applicationCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.applicationCode}</ns1:applicationCode><ns1:applicationID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.applicationID}</ns1:applicationID><ns1:collectionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.collectionID}</ns1:collectionID><ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.deviceCode}</ns1:deviceCode></ns3:dataCollectionHead>"
  end
end

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gmd="http://www.isotc211.org/2005/gmd"
    xmlns:gco="http://www.isotc211.org/2005/gco"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:gml320="http://www.opengis.net/gml"
    xmlns:gmx="http://www.isotc211.org/2005/gmx"
    xmlns:srv="http://www.isotc211.org/2005/srv"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:eml="eml://ecoinformatics.org/eml-2.1.1"
    exclude-result-prefixes="gmd gco gml gml320 gmx srv xlink eml"
    version="2.0">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- =========================================================
       PARAMETERS  (override from GeoNetwork formatter config)
       ========================================================= -->
  <!-- GBIF dataset type: occurrence | checklist | sampling-event | metadata -->
  <xsl:param name="datasetType" select="'occurrence'"/>
  <!-- Language tag for EML (ISO 639-1) -->
  <xsl:param name="metadataLanguage" select="'en'"/>

  <!-- =========================================================
       ROOT
       ========================================================= -->
  <xsl:template match="/">
    <xsl:apply-templates select="//gmd:MD_Metadata"/>
  </xsl:template>

  <!-- =========================================================
       MD_Metadata ? eml:eml
       ========================================================= -->
  <xsl:template match="gmd:MD_Metadata">

    <!-- Derive a package ID from the file identifier -->
    <xsl:variable name="packageId">
      <xsl:choose>
        <xsl:when test="normalize-space(gmd:fileIdentifier/gco:CharacterString) != ''">
          <xsl:value-of select="normalize-space(gmd:fileIdentifier/gco:CharacterString)"/>
        </xsl:when>
        <xsl:otherwise>unknown-id</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <eml:eml
        packageId="{$packageId}"
        system="http://gbif.org"
        scope="system"
        xml:lang="{$metadataLanguage}"
        xmlns:eml="eml://ecoinformatics.org/eml-2.1.1"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:dc="http://purl.org/dc/terms/"
        xsi:schemaLocation="eml://ecoinformatics.org/eml-2.1.1
                            http://rs.gbif.org/schema/eml-gbif-profile/1.2/eml.xsd">

      <!-- ?? dataset ???????????????????????????????????????? -->
      <dataset>

        <!-- alternateIdentifier: DOI or other identifiers -->
        <xsl:for-each select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:identifier/*/gmd:code/gco:CharacterString[normalize-space(.) != '']">
          <alternateIdentifier><xsl:value-of select="."/></alternateIdentifier>
        </xsl:for-each>

        <!-- title -->
        <xsl:call-template name="title"/>

        <!-- creator (responsible party with role = originator / author) -->
        <xsl:call-template name="responsibleParties">
          <xsl:with-param name="role"    select="'creator'"/>
          <xsl:with-param name="isoRole" select="'originator'"/>
        </xsl:call-template>

        <!-- metadataProvider (role = pointOfContact on metadata level) -->
        <xsl:call-template name="metadataProvider"/>

        <!-- associatedParty (all other roles) -->
        <xsl:call-template name="associatedParties"/>

        <!-- pubDate -->
        <xsl:call-template name="pubDate"/>

        <!-- language of the resource -->
        <xsl:call-template name="language"/>

        <!-- abstract -->
        <xsl:call-template name="abstract"/>

        <!-- keywordSet(s) -->
        <!-- Add keywords -->
        <xsl:if test="exists(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords)">
            <xsl:call-template name="keywords">
                <xsl:with-param name="keys" select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords" />
            </xsl:call-template>
        </xsl:if>

        <!-- additionalInfo -->
        <xsl:call-template name="additionalInfo"/>

        <!-- intellectualRights -->
        <xsl:call-template name="intellectualRights"/>

        <!-- distribution (online resources) -->
        <xsl:call-template name="distribution"/>

        <!-- coverage -->
        <xsl:call-template name="coverage"/>

        <!-- purpose ? maintenance -->
        <xsl:call-template name="maintenance"/>

        <!-- contact (role = pointOfContact on identification level) -->
        <xsl:call-template name="contact"/>

        <!-- methods -->
        <xsl:call-template name="methods"/>

        <!-- project -->
        <xsl:call-template name="project"/>

      </dataset>

      <!-- ?? additionalMetadata ????????????????????????????? -->
      <additionalMetadata>
        <metadata>
          <gbif>
            <dateStamp>
              <xsl:value-of select="
                if (normalize-space(gmd:dateStamp/gco:DateTime) != '')
                then normalize-space(gmd:dateStamp/gco:DateTime)
                else if (normalize-space(gmd:dateStamp/gco:Date) != '')
                     then normalize-space(gmd:dateStamp/gco:Date)
                     else format-date(current-date(),'[Y]-[M01]-[D01]')"/>
            </dateStamp>
            <hierarchyLevel>
              <xsl:value-of select="
                if (normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue) != '')
                then normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue)
                else 'dataset'"/>
            </hierarchyLevel>
            <!-- citation -->
            <xsl:call-template name="gbifCitation"/>
            <!-- physical data format / resource type -->
            <resourceLogoUrl/>
          </gbif>
        </metadata>
      </additionalMetadata>

    </eml:eml>
  </xsl:template>

  <!-- =========================================================
       TITLE
       ========================================================= -->
  <xsl:template name="title">
    <xsl:variable name="titleVal" select="normalize-space(
      gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString)"/>
    <title xml:lang="{$metadataLanguage}">
      <xsl:choose>
        <xsl:when test="$titleVal != ''"><xsl:value-of select="$titleVal"/></xsl:when>
        <xsl:otherwise>[No title]</xsl:otherwise>
      </xsl:choose>
    </title>
  </xsl:template>

  <!-- =========================================================
       ABSTRACT
       ========================================================= -->
  <xsl:template name="abstract">
    <xsl:variable name="abs" select="normalize-space(
      gmd:identificationInfo/*/gmd:abstract/gco:CharacterString)"/>
    <xsl:if test="$abs != ''">
      <abstract>
        <para><xsl:value-of select="$abs"/></para>
      </abstract>
    </xsl:if>
  </xsl:template>

  <!-- =========================================================
       RESPONSIBLE PARTY ? EML agent block
       Helper template builds one <creator>, <contact>, etc. block
       from a CI_ResponsibleParty element.
       ========================================================= -->
  <xsl:template name="buildAgent">
    <xsl:param name="party"/>
    <xsl:param name="emlRole"/>

    <!-- Single-valued address fields (ISO allows only one per CI_Address) -->
    <xsl:variable name="city"
      select="normalize-space(string(($party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city/gco:CharacterString)[1]))"/>
    <xsl:variable name="adminArea"
      select="normalize-space(string(($party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea/gco:CharacterString)[1]))"/>
    <xsl:variable name="postalCode"
      select="normalize-space(string(($party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:postalCode/gco:CharacterString)[1]))"/>
    <xsl:variable name="country"
      select="normalize-space(string(($party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country/gco:CharacterString)[1]))"/>

    <xsl:element name="{$emlRole}">

      <!-- individualName: one element per name entry -->
      <xsl:for-each select="$party/gmd:individualName/gco:CharacterString[normalize-space(.) != '']">
        <individualName>
          <xsl:analyze-string select="normalize-space(.)" regex="^(.*),\s*(.*)$">
            <xsl:matching-substring>
              <surName><xsl:value-of select="regex-group(1)"/></surName>
              <givenName><xsl:value-of select="regex-group(2)"/></givenName>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
              <!-- treat entire string as surname when no comma found -->
              <surName><xsl:value-of select="."/></surName>
            </xsl:non-matching-substring>
          </xsl:analyze-string>
        </individualName>
      </xsl:for-each>

      <!-- organizationName: one element per entry -->
      <xsl:for-each select="$party/gmd:organisationName/gco:CharacterString[normalize-space(.) != '']">
        <organizationName><xsl:value-of select="normalize-space(.)"/></organizationName>
      </xsl:for-each>

      <!-- positionName: one element per entry -->
      <xsl:for-each select="$party/gmd:positionName/gco:CharacterString[normalize-space(.) != '']">
        <positionName><xsl:value-of select="normalize-space(.)"/></positionName>
      </xsl:for-each>

      <!-- address: multiple deliveryPoints within one address block -->
      <xsl:if test="$party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/
                      gmd:deliveryPoint/gco:CharacterString[normalize-space(.) != '']
                    or $city != '' or $adminArea != '' or $postalCode != '' or $country != ''">
        <address>
          <xsl:for-each select="$party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/
                                  gmd:deliveryPoint/gco:CharacterString[normalize-space(.) != '']">
            <deliveryPoint><xsl:value-of select="normalize-space(.)"/></deliveryPoint>
          </xsl:for-each>
          <xsl:if test="$city        != ''"><city><xsl:value-of select="$city"/></city></xsl:if>
          <xsl:if test="$adminArea   != ''"><administrativeArea><xsl:value-of select="$adminArea"/></administrativeArea></xsl:if>
          <xsl:if test="$postalCode  != ''"><postalCode><xsl:value-of select="$postalCode"/></postalCode></xsl:if>
          <xsl:if test="$country     != ''"><country><xsl:value-of select="$country"/></country></xsl:if>
        </address>
      </xsl:if>

      <!-- phone: one element per voice number -->
      <xsl:for-each select="$party/gmd:contactInfo/gmd:CI_Contact/gmd:phone/
                              gmd:CI_Telephone/gmd:voice/gco:CharacterString[normalize-space(.) != '']">
        <phone><xsl:value-of select="normalize-space(.)"/></phone>
      </xsl:for-each>

      <!-- electronicMailAddress: one element per address -->
      <xsl:for-each select="$party/gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/
                              gmd:electronicMailAddress/gco:CharacterString[normalize-space(.) != '']">
        <electronicMailAddress><xsl:value-of select="normalize-space(.)"/></electronicMailAddress>
      </xsl:for-each>

      <!-- onlineUrl: one element per online resource -->
      <xsl:for-each select="$party/gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/
                              gmd:CI_OnlineResource/gmd:linkage/gmd:URL[normalize-space(.) != '']">
        <onlineUrl><xsl:value-of select="normalize-space(.)"/></onlineUrl>
      </xsl:for-each>

      <!-- role (for associatedParty only) -->
      <xsl:if test="$emlRole = 'associatedParty'">
        <role>
          <xsl:value-of select="normalize-space($party/gmd:role/gmd:CI_RoleCode/@codeListValue)"/>
        </role>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-- =========================================================
       PARTY  (placeholder – populate as needed)
       ========================================================= -->
<xsl:template name="party">
    <xsl:param name = "party" />
    <xsl:apply-templates select="$party/*"/>
    <xsl:if test="$party//gmd:voice/gco:CharacterString!=''">
        <phone><xsl:value-of select="normalize-space($party//gmd:voice/gco:CharacterString)"/></phone>
    </xsl:if>
    <xsl:if test="$party//gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString!=''">
        <electronicMailAddress><xsl:value-of select="normalize-space($party//gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString)"/></electronicMailAddress>
    </xsl:if>
    <xsl:if test="$party//gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL!=''">
        <onlineUrl><xsl:value-of select="normalize-space($party//gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL)"/></onlineUrl>
    </xsl:if>
</xsl:template>

<!-- Add an individualName -->
<xsl:template match="gmd:individualName">
    <individualName>
        <surName><xsl:value-of select="normalize-space(gco:CharacterString)"/></surName>
    </individualName>
</xsl:template>

<!-- Add an organizationName -->
<xsl:template match="gmd:organisationName">
    <organizationName><xsl:value-of select="normalize-space(gco:CharacterString)"/></organizationName>
</xsl:template>

<!-- Add a positionName -->
<xsl:template match="gmd:positionName">
    <positionName><xsl:value-of select="normalize-space(gco:CharacterString)"/></positionName>
</xsl:template>

<!-- voice, email, and role are all noops so they can be reordered correctly -->
<xsl:template match="gmd:voice" />
<xsl:template match="gmd:electronicMailAddress" />
<xsl:template match="gmd:role" />
<xsl:template match="gmd:onlineResource" />

<!-- Add an Address -->
<xsl:template match="gmd:CI_Address"> 
    <xsl:if test="gmd:deliveryPoint/gco:CharacterString!='' or gmd:city/gco:CharacterString!='' or gmd:administrativeArea/gco:CharacterString!='' or gmd:postalCode/gco:CharacterString!='' or gmd:country/gco:CharacterString!=''">
    <address>
        <xsl:if test="gmd:deliveryPoint/gco:CharacterString!=''">
            <deliveryPoint><xsl:value-of select="normalize-space(gmd:deliveryPoint/gco:CharacterString)"/></deliveryPoint>
        </xsl:if>
        <xsl:if test="gmd:city/gco:CharacterString!=''">
            <city><xsl:value-of select="normalize-space(gmd:city/gco:CharacterString)"/></city>
        </xsl:if>
        <xsl:if test="gmd:administrativeArea/gco:CharacterString!=''">
            <administrativeArea><xsl:value-of select="normalize-space(gmd:administrativeArea/gco:CharacterString)"/></administrativeArea>
        </xsl:if>
        <xsl:if test="gmd:postalCode/gco:CharacterString!=''">
            <postalCode><xsl:value-of select="normalize-space(gmd:postalCode/gco:CharacterString)"/></postalCode>
        </xsl:if>
        <xsl:if test="gmd:country/gco:CharacterString!=''">
            <country><xsl:value-of select="normalize-space(gmd:country/gco:CharacterString)"/></country>
        </xsl:if>
    </address>
    </xsl:if>
</xsl:template>

<!-- Add creator -->
<xsl:template name="creators">
    <xsl:param name = "doc" />
    <xsl:choose>
        <!-- First add any authors from the gmd:citation -->
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="author"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="author"]]'>
                <creator>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </creator>
            </xsl:for-each>
        </xsl:when>
        <!-- Alternatively, add authors from anywhere in the document -->
        <xsl:when test='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="author"]] != "" '>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="author"]]'>
                <creator>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </creator>
            </xsl:for-each>
        </xsl:when>
        <!-- Alternatively, add principalInvestigators from anywhere in the document -->
        <xsl:when test='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="principalInvestigator"]] != "" '>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="principalInvestigator"]]'>
                <creator>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </creator>
            </xsl:for-each>
        </xsl:when>
        <!-- Alternatively, add pointOfContact from the citation in the document -->
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]] != "" '>
            <xsl:for-each select='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]]'>
                <creator>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </creator>
            </xsl:for-each>
        </xsl:when>
        <!-- Alternatively, add pointOfContact from anywhere in the document -->
        <xsl:when test='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]] != "" '>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]]'>
                <creator>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </creator>
            </xsl:for-each>
        </xsl:when>
        <!-- Finally, if all else fails, add the Arctic Data Center -->
        <xsl:otherwise>
            <creator>
                <organizationName>NSF Arctic Data Center</organizationName>
            </creator>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
        
<!-- Add contacts -->
<xsl:template name="contacts">
    <xsl:param name = "doc" />
    <xsl:choose>
        <!-- Add contacts from the citation in the document -->
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]]'>
                <contact>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </contact>
            </xsl:for-each>
        </xsl:when>
        <!-- Alternatively, add contacts from anywhere in the document -->
        <xsl:when test='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]] != "" '>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="pointOfContact"]]'>
                <contact>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </contact>
            </xsl:for-each>
        </xsl:when>
        <!-- Alternatively, add the first author as a contact -->
        <!--
        <xsl:when test='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="author"]] != "" '>
            <contact>
                <xsl:call-template name="party">
                    <xsl:with-param name="party" select = '$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="author"]][1]' />
                </xsl:call-template>
            </contact>
        </xsl:when>
        -->
        <!-- Finally, if all else fails, add the Arctic Data Center -->
        <xsl:otherwise>
            <contact>
                <organizationName>NSF Arctic Data Center</organizationName>
            </contact>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Add publishers
    First, check to see if publishers are listed in the gmd:citation, and if so, use them;
    If not, then search the whole document and use any found.  This avoids duplication.
-->
<xsl:template name="publishers">
    <xsl:param name = "doc" />
    <!-- publisher -->
    <xsl:choose>
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="publisher"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="publisher"]]'>
                <publisher>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </publisher>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="publisher"]]'>
                <publisher>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                </publisher>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Add associatedParty: principalInvestigator
    First, check to see if principalInvestigators are listed in the gmd:citation, and if so, use them;
    If not, then search the whole document and use any found.  This avoids duplication.
-->
<xsl:template name="additional-parties">
    <xsl:param name = "doc" />
    <!-- Roles to be handled: originator|principalInvestigator|resourceProvider|distributor -->

    <!-- principalInvestigators -->
    <xsl:choose>
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="principalInvestigator"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="principalInvestigator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>principalInvestigator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="principalInvestigator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>principalInvestigator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>

    <!-- coPrincipalInvestigator -->
    <xsl:choose>
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="coPrincipalInvestigator"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="coPrincipalInvestigator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>coPrincipalInvestigator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="coPrincipalInvestigator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>coPrincipalInvestigator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>

    <!-- collaboratingPrincipalInvestigator -->
    <xsl:choose>
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="collaboratingPrincipalInvestigator"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="collaboratingPrincipalInvestigator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>collaboratingPrincipalInvestigator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="collaboratingPrincipalInvestigator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>collaboratingPrincipalInvestigator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>

    <!-- originators -->
    <xsl:choose>
        <xsl:when test='$doc/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="originator"]]!=""'>
            <xsl:for-each select='gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="originator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>originator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select='$doc//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue="originator"]]'>
                <associatedParty>
                    <xsl:call-template name="party">
                        <xsl:with-param name="party" select = "." />
                    </xsl:call-template>
                    <role>originator</role>
                </associatedParty>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

  <!-- =========================================================
       CREATOR  (ISO originator / author / owner / resourceProvider)
       ========================================================= -->
  <xsl:template name="responsibleParties">
    <xsl:param name="role"/>
    <xsl:param name="isoRole"/>
    <xsl:for-each select="gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty
                          [normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue) = $isoRole]">
      <xsl:call-template name="buildAgent">
        <xsl:with-param name="party"   select="."/>
        <xsl:with-param name="emlRole" select="$role"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- fallback: if no originator found, use first pointOfContact as creator -->
    <xsl:if test="not(gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty
                      [normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue) = $isoRole])
                  and $role = 'creator'">
      <xsl:for-each select="(gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty)[1]">
        <xsl:call-template name="buildAgent">
          <xsl:with-param name="party"   select="."/>
          <xsl:with-param name="emlRole" select="'creator'"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <!-- =========================================================
       METADATA PROVIDER  (ISO metadataPointOfContact or pointOfContact)
       ========================================================= -->
  <xsl:template name="metadataProvider">
    <xsl:variable name="mdContact" select="gmd:contact/gmd:CI_ResponsibleParty"/>
    <xsl:if test="$mdContact">
      <xsl:call-template name="buildAgent">
        <xsl:with-param name="party"   select="$mdContact"/>
        <xsl:with-param name="emlRole" select="'metadataProvider'"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- =========================================================
       ASSOCIATED PARTIES  (all roles except originator)
       ========================================================= -->
  <xsl:template name="associatedParties">
    <xsl:for-each select="gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty
                          [normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue) != 'originator']">
      <xsl:call-template name="buildAgent">
        <xsl:with-param name="party"   select="."/>
        <xsl:with-param name="emlRole" select="'associatedParty'"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- =========================================================
       CONTACT  (role = pointOfContact on identification block)
       ========================================================= -->
  <xsl:template name="contact">
    <xsl:variable name="poc" select="gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty
                                     [normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue) = 'pointOfContact'][1]"/>
    <xsl:choose>
      <xsl:when test="$poc">
        <xsl:call-template name="buildAgent">
          <xsl:with-param name="party"   select="$poc"/>
          <xsl:with-param name="emlRole" select="'contact'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- Use metadata-level contact as fallback -->
        <xsl:if test="gmd:contact/gmd:CI_ResponsibleParty">
          <xsl:call-template name="buildAgent">
            <xsl:with-param name="party"   select="gmd:contact/gmd:CI_ResponsibleParty"/>
            <xsl:with-param name="emlRole" select="'contact'"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- =========================================================
       PUBLICATION DATE
       ========================================================= -->
  <xsl:template name="pubDate">
    <xsl:variable name="pubDateVal" select="normalize-space(
      gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/
      gmd:date/gmd:CI_Date[gmd:dateType/gmd:CI_DateTypeCode/@codeListValue='publication']/
      gmd:date/gco:DateTime)"/>
    <xsl:variable name="pubDateOnly" select="normalize-space(
      gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/
      gmd:date/gmd:CI_Date[gmd:dateType/gmd:CI_DateTypeCode/@codeListValue='publication']/
      gmd:date/gco:Date)"/>
    <xsl:choose>
      <xsl:when test="$pubDateVal != ''">
        <pubDate><xsl:value-of select="substring($pubDateVal,1,10)"/></pubDate>
      </xsl:when>
      <xsl:when test="$pubDateOnly != ''">
        <pubDate><xsl:value-of select="$pubDateOnly"/></pubDate>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- =========================================================
       LANGUAGE
       ========================================================= -->
  <xsl:template name="language">
    <xsl:variable name="lang" select="normalize-space(
      gmd:identificationInfo/*/gmd:language/gco:CharacterString)"/>
    <language>
      <xsl:choose>
        <xsl:when test="$lang != ''"><xsl:value-of select="$lang"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$metadataLanguage"/></xsl:otherwise>
      </xsl:choose>
    </language>
  </xsl:template>

  <!-- =========================================================
       KEYWORDS
       ========================================================= -->
<xsl:template name="keywords">
    <xsl:param name = "keys" />
    <xsl:for-each select="$keys">
        <xsl:variable name="kw-type" select="./gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode/@codeListValue" />
        <keywordSet>    
            <xsl:for-each select="./gmd:MD_Keywords/gmd:keyword/(gco:CharacterString | gmx:Anchor)">
                <keyword>
                    <!-- ISO: discipline, place, stratum, temporal, theme -->
                    <!-- EML:             place, stratum, temporal, theme, taxonomic -->
                    <xsl:if test="$kw-type != '' and (
                        $kw-type = 'place' or $kw-type = 'stratum' or 
                        $kw-type = 'temporal' or $kw-type = 'theme')">
                        <xsl:attribute name="keywordType"><xsl:value-of select="normalize-space($kw-type)"/></xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(.)" />
                </keyword>
            </xsl:for-each>
            <xsl:choose>
                <xsl:when test="exists(./gmd:MD_Keywords/gmd:thesaurusName)">
                    <xsl:choose>
                        <xsl:when test="normalize-space(./gmd:MD_Keywords/gmd:thesaurusName/gmd:CI_Citation/gmd:collectiveTitle/(gco:CharacterString | gmx:Anchor)) != ''">
                            <keywordThesaurus>
                                <xsl:value-of select="normalize-space(./gmd:MD_Keywords/gmd:thesaurusName/gmd:CI_Citation/gmd:collectiveTitle/(gco:CharacterString | gmx:Anchor))" />
                            </keywordThesaurus>
                        </xsl:when>
                        <xsl:otherwise>
                            <keywordThesaurus>
                                <xsl:value-of select="normalize-space(./gmd:MD_Keywords/gmd:thesaurusName/gmd:CI_Citation/gmd:title/(gco:CharacterString | gmx:Anchor))" />
                            </keywordThesaurus>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <keywordThesaurus>ICES keywords</keywordThesaurus>
                </xsl:otherwise>
            </xsl:choose>
        </keywordSet>
    </xsl:for-each>
</xsl:template>

  <!-- =========================================================
       ADDITIONAL INFO (supplementalInformation)
       ========================================================= -->
  <xsl:template name="additionalInfo">
    <xsl:variable name="suppl" select="normalize-space(
      gmd:identificationInfo/*/gmd:supplementalInformation/gco:CharacterString)"/>
    <xsl:if test="$suppl != ''">
      <additionalInfo>
        <para><xsl:value-of select="$suppl"/></para>
      </additionalInfo>
    </xsl:if>
  </xsl:template>

  <!-- =========================================================
       INTELLECTUAL RIGHTS  (useLimitation + accessConstraints)
       ========================================================= -->
<xsl:template name="intellectualRights">

  <xsl:variable name="useLim"
    select="normalize-space(string((gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_Constraints/
      gmd:useLimitation/gco:CharacterString)[1]))"/>

  <xsl:variable name="legalUse"
    select="normalize-space(string((gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_LegalConstraints/
      gmd:useLimitation/gco:CharacterString)[1]))"/>

  <xsl:variable name="accessCode"
    select="normalize-space(string((gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_LegalConstraints/
      gmd:accessConstraints/gmd:MD_RestrictionCode/@codeListValue)[1]))"/>

  <xsl:variable name="otherConst"
    select="normalize-space(string((gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_LegalConstraints/
      gmd:otherConstraints/gco:CharacterString)[1]))"/>

  <intellectualRights>
    <para>
      <xsl:choose>
        <xsl:when test="$otherConst != ''">
          <xsl:value-of select="$otherConst"/>
        </xsl:when>
        <xsl:when test="$legalUse != ''">
          <xsl:value-of select="$legalUse"/>
        </xsl:when>
        <xsl:when test="$useLim != ''">
          <xsl:value-of select="$useLim"/>
        </xsl:when>
        <xsl:when test="$accessCode != ''">
          <xsl:text>Access constraint: </xsl:text>
          <xsl:value-of select="$accessCode"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>No usage conditions have been specified. Please contact the data provider.</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </para>
  </intellectualRights>

</xsl:template>

  <!-- =========================================================
       DISTRIBUTION  (online resources ? distribution/online/url)
       ========================================================= -->
  <xsl:template name="distribution">
    <xsl:for-each select="gmd:distributionInfo/gmd:MD_Distribution/
                          gmd:transferOptions/gmd:MD_DigitalTransferOptions/
                          gmd:onLine/gmd:CI_OnlineResource
                          [normalize-space(gmd:linkage/gmd:URL) != '']">
      <distribution scope="document">
        <online>
          <url function="download"><xsl:value-of select="normalize-space(gmd:linkage/gmd:URL)"/></url>
        </online>
      </distribution>
    </xsl:for-each>
  </xsl:template>

  <!-- =========================================================
       COVERAGE  (geographic + temporal + taxonomic placeholder)
       ========================================================= -->
  <xsl:template name="coverage">

    <!-- ?? geographic coverage ???????????????????????????? -->
    <xsl:for-each select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/
                          gmd:geographicElement/gmd:EX_GeographicBoundingBox">
      <xsl:variable name="west"  select="normalize-space(gmd:westBoundLongitude/gco:Decimal)"/>
      <xsl:variable name="east"  select="normalize-space(gmd:eastBoundLongitude/gco:Decimal)"/>
      <xsl:variable name="south" select="normalize-space(gmd:southBoundLatitude/gco:Decimal)"/>
      <xsl:variable name="north" select="normalize-space(gmd:northBoundLatitude/gco:Decimal)"/>
      <xsl:if test="$west != '' and $east != '' and $south != '' and $north != ''">
        <coverage>
          <geographicCoverage>
            <!-- description from EX_GeographicDescription if available -->
            <xsl:variable name="geogDesc" select="normalize-space(
              ../../gmd:geographicElement/gmd:EX_GeographicDescription/
              gmd:geographicIdentifier/gmd:MD_Identifier/gmd:code/gco:CharacterString)"/>
            <geographicDescription>
              <xsl:choose>
                <xsl:when test="$geogDesc != ''"><xsl:value-of select="$geogDesc"/></xsl:when>
                <xsl:otherwise>Bounding box derived from ISO metadata</xsl:otherwise>
              </xsl:choose>
            </geographicDescription>
            <boundingCoordinates>
              <westBoundingCoordinate><xsl:value-of select="$west"/></westBoundingCoordinate>
              <eastBoundingCoordinate><xsl:value-of select="$east"/></eastBoundingCoordinate>
              <northBoundingCoordinate><xsl:value-of select="$north"/></northBoundingCoordinate>
              <southBoundingCoordinate><xsl:value-of select="$south"/></southBoundingCoordinate>
            </boundingCoordinates>
          </geographicCoverage>

          <!-- ?? temporal coverage ???????????????????????? -->
          <xsl:call-template name="temporalCoverage"/>

          <!-- ?? taxonomic coverage (placeholder) ?????????? -->
          <!-- NOTE: ISO 19139 has no equivalent for taxonomic information.
               Populate the block below manually or via post-processing
               using a species checklist or occurrence data. -->
          <!--
          <taxonomicCoverage>
            <generalTaxonomicCoverage>All taxa recorded in the dataset</generalTaxonomicCoverage>
            <taxonomicClassification>
              <taxonRankName>Kingdom</taxonRankName>
              <taxonRankValue>Animalia</taxonRankValue>
            </taxonomicClassification>
          </taxonomicCoverage>
          -->
        </coverage>
      </xsl:if>
    </xsl:for-each>

    <!-- Temporal coverage without geographic (if no bbox present) -->
    <xsl:if test="not(gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/
                      gmd:geographicElement/gmd:EX_GeographicBoundingBox)">
      <xsl:variable name="hasTime" select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/
                                           gmd:temporalElement/gmd:EX_TemporalExtent"/>
      <xsl:if test="$hasTime">
        <coverage>
          <xsl:call-template name="temporalCoverage"/>
        </coverage>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- ?? temporal coverage (reusable) ???????????????????????? -->
  <xsl:template name="temporalCoverage">
    <xsl:for-each select="../../gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent |
                          ../../../gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent">

      <!-- GML 3.2 TimePeriod -->
      <xsl:variable name="begin" select="normalize-space(
        (gml:TimePeriod/gml:beginPosition | gml320:TimePeriod/gml320:beginPosition)[1])"/>
      <xsl:variable name="end"   select="normalize-space(
        (gml:TimePeriod/gml:endPosition   | gml320:TimePeriod/gml320:endPosition)[1])"/>
      <xsl:variable name="instant" select="normalize-space(
        (gml:TimeInstant/gml:timePosition | gml320:TimeInstant/gml320:timePosition)[1])"/>

      <xsl:choose>
        <xsl:when test="$begin != '' and $end != ''">
          <temporalCoverage>
            <rangeOfDates>
              <beginDate><calendarDate><xsl:value-of select="substring($begin,1,10)"/></calendarDate></beginDate>
              <endDate><calendarDate><xsl:value-of select="substring($end,1,10)"/></calendarDate></endDate>
            </rangeOfDates>
          </temporalCoverage>
        </xsl:when>
        <xsl:when test="$begin != ''">
          <temporalCoverage>
            <rangeOfDates>
              <beginDate><calendarDate><xsl:value-of select="substring($begin,1,10)"/></calendarDate></beginDate>
              <endDate><calendarDate><xsl:value-of select="format-date(current-date(),'[Y]-[M01]-[D01]')"/></calendarDate></endDate>
            </rangeOfDates>
          </temporalCoverage>
        </xsl:when>
        <xsl:when test="$instant != ''">
          <temporalCoverage>
            <singleDateTime>
              <calendarDate><xsl:value-of select="substring($instant,1,10)"/></calendarDate>
            </singleDateTime>
          </temporalCoverage>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- =========================================================
       MAINTENANCE
       ========================================================= -->
  <xsl:template name="maintenance">
    <xsl:variable name="freq" select="normalize-space(
      gmd:identificationInfo/*/gmd:resourceMaintenance/gmd:MD_MaintenanceInformation/
      gmd:maintenanceAndUpdateFrequency/gmd:MD_MaintenanceFrequencyCode/@codeListValue)"/>
    <xsl:if test="$freq != ''">
      <maintenance>
        <description>
          <para>
            <xsl:choose>
              <xsl:when test="$freq = 'continual'">Data is updated continually.</xsl:when>
              <xsl:when test="$freq = 'daily'">Data is updated daily.</xsl:when>
              <xsl:when test="$freq = 'weekly'">Data is updated weekly.</xsl:when>
              <xsl:when test="$freq = 'fortnightly'">Data is updated fortnightly.</xsl:when>
              <xsl:when test="$freq = 'monthly'">Data is updated monthly.</xsl:when>
              <xsl:when test="$freq = 'quarterly'">Data is updated quarterly.</xsl:when>
              <xsl:when test="$freq = 'biannually'">Data is updated biannually.</xsl:when>
              <xsl:when test="$freq = 'annually'">Data is updated annually.</xsl:when>
              <xsl:when test="$freq = 'asNeeded'">Data is updated as needed.</xsl:when>
              <xsl:when test="$freq = 'irregular'">Data is updated irregularly.</xsl:when>
              <xsl:when test="$freq = 'notPlanned'">No future updates are planned.</xsl:when>
              <xsl:when test="$freq = 'unknown'">Update frequency is unknown.</xsl:when>
              <xsl:otherwise>Update frequency: <xsl:value-of select="$freq"/></xsl:otherwise>
            </xsl:choose>
          </para>
        </description>
        <maintenanceUpdateFrequency>
          <xsl:choose>
            <xsl:when test="$freq = 'continual'">continually</xsl:when>
            <xsl:when test="$freq = 'daily'">daily</xsl:when>
            <xsl:when test="$freq = 'weekly'">weekly</xsl:when>
            <xsl:when test="$freq = 'monthly'">monthly</xsl:when>
            <xsl:when test="$freq = 'annually'">annually</xsl:when>
            <xsl:when test="$freq = 'asNeeded'">asNeeded</xsl:when>
            <xsl:when test="$freq = 'irregular'">irregular</xsl:when>
            <xsl:when test="$freq = 'notPlanned'">notPlanned</xsl:when>
            <xsl:otherwise>unknown</xsl:otherwise>
          </xsl:choose>
        </maintenanceUpdateFrequency>
      </maintenance>
    </xsl:if>
  </xsl:template>

  <!-- =========================================================
       METHODS  (lineage statement ? methodStep)
       ========================================================= -->
  <xsl:template name="methods">
    <xsl:variable name="lineage" select="normalize-space(
      gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/
      gmd:statement/gco:CharacterString)"/>
    <xsl:if test="$lineage != ''">
      <methods>
        <methodStep>
          <description>
            <para><xsl:value-of select="$lineage"/></para>
          </description>
        </methodStep>
      </methods>
    </xsl:if>
  </xsl:template>

  <!-- =========================================================
       PROJECT  (credit / purpose ? project)
       ========================================================= -->
   <xsl:template name="project">
        <xsl:variable name="awardCount" select="count(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:credit)" />
        <!-- Add funding elements -->
        <xsl:if test="$awardCount &gt; 0">
            <project>
                <!-- Add the project title -->
                <title><xsl:value-of select="normalize-space(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title[1]/gco:CharacterString)"/></title>

                <!-- Add the project abstract -->
                <xsl:if test="normalize-space(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract[1]/gco:CharacterString) != ''">
                    <abstract><xsl:value-of select="normalize-space(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract[1]/gco:CharacterString)"/></abstract>
                </xsl:if>

                <!-- Add personnel from the PI list or the author list -->
                <xsl:choose>
                    <!-- Select PIs from the citation -->
                    <xsl:when test="exists(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue='principalInvestigator' or @codeListValue='coPrincipalInvestigator' or @codeListValue='collaboratingPrincipalInvestigator']])">
                        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue='principalInvestigator' or @codeListValue='coPrincipalInvestigator' or @codeListValue='collaboratingPrincipalInvestigator']]">
                            <personnel>
                                <xsl:call-template name="buildAgent">
                                    <xsl:with-param name="party" select="." />
                                    <xsl:with-param name="emlRole" select="'personnel'" />
                                </xsl:call-template>
                                <role>principalInvestigator</role>
                            </personnel>
                        </xsl:for-each>
                    </xsl:when>
                    <!-- Alternatively, select PIs from anywhere in the doc -->
                    <xsl:when test="exists(//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue='principalInvestigator' or @codeListValue='coPrincipalInvestigator' or @codeListValue='collaboratingPrincipalInvestigator']])">
                        <xsl:for-each select="//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue='principalInvestigator' or @codeListValue='coPrincipalInvestigator' or @codeListValue='collaboratingPrincipalInvestigator']]">
                            <personnel>
                                <xsl:call-template name="buildAgent">
                                    <xsl:with-param name="party" select="." />
                                    <xsl:with-param name="emlRole" select="'personnel'" />
                                </xsl:call-template>
                                <role>principalInvestigator</role>
                            </personnel>
                        </xsl:for-each>
                    </xsl:when>
                    <!-- Otherwise, select the author anywhere in the document -->
                    <xsl:otherwise>
                        <xsl:for-each select="//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue='author']]">
                            <personnel>
                                <xsl:call-template name="buildAgent">
                                    <xsl:with-param name="party" select="." />
                                    <xsl:with-param name="emlRole" select="'personnel'" />
                                </xsl:call-template>
                                <role>principalInvestigator</role>
                            </personnel>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- Add all of the funding from gmd:credit -->
                <funding>
                    <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:credit">
                        <para><xsl:value-of select="."/></para>
                    </xsl:for-each>
                </funding>
            </project>
        </xsl:if>
            
    </xsl:template>





  <!-- =========================================================
       GBIF CITATION  (citation element in additionalMetadata)
       ========================================================= -->
  <xsl:template name="gbifCitation">
    <xsl:variable name="title" select="normalize-space(
      gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString)"/>
    <xsl:variable name="orgName" select="normalize-space(
      (gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty/
       gmd:organisationName/gco:CharacterString)[1])"/>
    <xsl:variable name="pubYear" select="substring(normalize-space(
      gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/
      gmd:date/gmd:CI_Date[gmd:dateType/gmd:CI_DateTypeCode/@codeListValue='publication']/
      gmd:date/gco:Date),1,4)"/>

    <citation>
      <xsl:if test="$orgName != ''">
        <xsl:value-of select="$orgName"/>
        <xsl:if test="$pubYear != ''"> (<xsl:value-of select="$pubYear"/>)</xsl:if>
        <xsl:if test="$title   != ''">.&#160;<xsl:value-of select="$title"/>.</xsl:if>
      </xsl:if>
    </citation>
  </xsl:template>

</xsl:stylesheet>





<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template match="/">
        <html>
            <body>
                <h2>
                    Replication Link Analysis Report
                </h2>
                <xsl:if test="ReplicationLinkAnalysis/@SourceSiteCode!=''">
                    <xsl:if test="ReplicationLinkAnalysis/@TargetSiteCode!=''">
                <h3>
                    <xsl:value-of select="ReplicationLinkAnalysis/@SourceSiteCode"/> - <xsl:value-of select="ReplicationLinkAnalysis/@TargetSiteCode"/>
                </h3>
                </xsl:if>
                </xsl:if>
                <table BORDER="1">
                    <tr bgcolor="#9acd32">
                        <th>RuleName</th>
                        <th>Parameters</th>
                        <th>HasRun</th>
                        <th>HasPassed</th>
                        <th>Details</th>
                        <th>ErrorMessage</th>
                    </tr>
                    <xsl:for-each select="ReplicationLinkAnalysis/IsServiceRunning | ReplicationLinkAnalysis/IsComponentRunning | ReplicationLinkAnalysis/IsRcmCreateInstanceWorking | ReplicationLinkAnalysis/IsSqlDynamicPortEnabled | ReplicationLinkAnalysis/IsSqlVersionCorrect | ReplicationLinkAnalysis/IsNetworkDownBetweenSites | ReplicationLinkAnalysis/IsConfigMgrDatabaseOutOfSpace | ReplicationLinkAnalysis/IsTempDatabaseOutOfSpace | ReplicationLinkAnalysis/DoesBrokerConfigurationExist | ReplicationLinkAnalysis/DoesBrokerPortConflictExist | ReplicationLinkAnalysis/DoesBrokerCertificateMatch | ReplicationLinkAnalysis/DoesValidPublicKeyExchangeExist | ReplicationLinkAnalysis/DoesValidLocalSystemSqlLoginExist | ReplicationLinkAnalysis/IsTransmissionStuck | ReplicationLinkAnalysis/IsBrokerDisabled | ReplicationLinkAnalysis/IsSysCommitTabError | ReplicationLinkAnalysis/DoesFileReplicationRouteExist | ReplicationLinkAnalysis/IsSiteActive | ReplicationLinkAnalysis/IsTimeInSync | ReplicationLinkAnalysis/IsSendHistoryNull | ReplicationLinkAnalysis/DoesKeyConflictExist | ReplicationLinkAnalysis/CheckDegradedLinks | ReplicationLinkAnalysis/CheckFailedLinks | ReplicationLinkAnalysis/IsQueueDisabled | ReplicationLinkAnalysis/IsChangeTrackingEnabled | ReplicationLinkAnalysis/IsLinkedServerConnectionWorking">
                        <tr>
                            <td>
                                <xsl:value-of select="@RuleName"/>
                            </td>
                            <td>
                                <table>
                                    <xsl:for-each select="Parameters/Parameter">
                                        <tr>
                                            <td>
                                                <xsl:value-of select="@Name"/>
                                            </td>
                                            <td>
                                                <xsl:value-of select="@Value"/>
                                            </td>
                                        </tr>
                                    </xsl:for-each>
                                </table>
                            </td>
                            <xsl:choose>
                                <xsl:when test="Result/@HasRun = 'False'">
                                    <td bgcolor="#FF0000" >
                                        <xsl:value-of select="Result/@HasRun"/>
                                    </td>
                                    <td>
                                        <xsl:value-of select="Result/@HasPassed"/>
                                    </td>
                                </xsl:when>
                                <xsl:otherwise>
                                    <td>
                                        <xsl:value-of select="Result/@HasRun"/>
                                    </td>
                                    <xsl:choose>
                                        <xsl:when test="Result/@HasPassed = 'False'">
                                            <td bgcolor="#FF0000">
                                                <xsl:value-of select="Result/@HasPassed"/>
                                            </td>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <td>
                                                <xsl:value-of select="Result/@HasPassed"/>
                                            </td>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                            <td>
                                <table>
                                    <xsl:for-each select="Description/Detail">
                                        <tr>
                                            <td>
                                                <xsl:value-of select="@Name"/>
                                            </td>
                                            <td>
                                                <xsl:value-of select="@Value"/>
                                            </td>
                                        </tr>
                                    </xsl:for-each>
                                </table>
                            </td>
                            <td>
                                <xsl:value-of select="Description/ErrorMessage/@Content"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>

                <br/>
                <br/>
                <table BORDER="1">
                    <tr bgcolor="#9acd32">
                        <th>RemediationName</th>
                        <th>Parameters</th>
                        <th>HasRun</th>
                        <th>HasPassed</th>
                    </tr>
                    <xsl:for-each select="ReplicationLinkAnalysis/RuleRemediationSteps/RuleRemediationStep">
                        <tr>
                            <td>
                                <xsl:value-of select="@Name"/>
                            </td>
                            <td>
                                <table>
                                    <xsl:for-each select="Parameter">
                                        <tr>
                                            <td>
                                                <xsl:value-of select="@Value"/>
                                            </td>
                                        </tr>
                                    </xsl:for-each>
                                </table>
                            </td>
                            <xsl:choose>
                                <xsl:when test="Result/@HasRun = 'False'">
                                    <td bgcolor="#FF0000">
                                        <xsl:value-of select="Result/@HasRun"/>
                                    </td>
                                    <td>
                                        <xsl:value-of select="Result/@HasPassed"/>
                                    </td>
                                </xsl:when>
                                <xsl:otherwise>
                                    <td>
                                        <xsl:value-of select="Result/@HasRun"/>
                                    </td>
                                    <xsl:choose>
                                        <xsl:when test="Result/@HasPassed = 'False'">
                                            <td bgcolor="#FF0000">
                                                <xsl:value-of select="Result/@HasPassed"/>
                                            </td>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <td>
                                                <xsl:value-of select="Result/@HasPassed"/>
                                            </td>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tr>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>


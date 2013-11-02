<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0"
                exclude-result-prefixes="#default">

    <xsl:output method="xml"
                indent="yes"
                doctype-system="psm.dtd"/>

    <xsl:key name="classifier" use="@xmi.id"
             match="//Foundation.Core.Class|//Foundation.Core.Interface|//Foundation.Core.DataType"/>

    <xsl:key name="generalization" use="@xmi.id"
             match="//Foundation.Core.Generalization"/>

    <xsl:key name="abstraction" use="@xmi.id"
             match="//Foundation.Core.Abstraction"/>

    <xsl:key name="multiplicity" use="@xmi.id"
             match="//Foundation.Data_Types.Multiplicity"/>

    <xsl:template match="/XMI/XMI.content">
        <generated>
            <xsl:apply-templates select="Model_Management.Model[@xmi.id]" mode="psm"/>
        </generated>
    </xsl:template>

    <xsl:template match="Model_Management.Model" mode="psm">
        <platformSpecificModel type="Hibernate3" src="{Foundation.Core.ModelElement.name}">
            <xsl:apply-templates select="//Foundation.Core.Interface[@xmi.id]" mode="psm">
                <xsl:sort select="Foundation.Core.ModelElement.name"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="//Foundation.Core.Class[@xmi.id]" mode="psm">
                <xsl:sort select="Foundation.Core.ModelElement.name"/>
            </xsl:apply-templates>
        </platformSpecificModel>
    </xsl:template>


    <xsl:template match="Foundation.Core.Class" mode="psm">
        <xsl:variable name="element_name" select="Foundation.Core.ModelElement.name"/>
        <xsl:variable name="xmi_id" select="@xmi.id"/>

        <class name="{$element_name}">
            <xsl:apply-templates mode="psm-specifications"
                                 select="Foundation.Core.ModelElement.clientDependency/Foundation.Core.Abstraction"/>
            <xsl:apply-templates mode="psm-supertypes"
                                 select="Foundation.Core.GeneralizableElement.generalization/Foundation.Core.Generalization"/>
            <xsl:apply-templates mode="psm-attributes"
                                 select="Foundation.Core.Classifier.feature/Foundation.Core.Attribute"/>
            <xsl:apply-templates mode="psm-operations"
                                 select="Foundation.Core.Classifier.feature/Foundation.Core.Operation"/>

            <xsl:for-each select="//Foundation.Core.AssociationEnd[Foundation.Core.AssociationEnd.type/*/@xmi.idref=$xmi_id]">
                <xsl:for-each select="preceding-sibling::Foundation.Core.AssociationEnd | following-sibling::Foundation.Core.AssociationEnd">
                    <xsl:apply-templates select="." mode="psm-associations"/>
                </xsl:for-each>
            </xsl:for-each>
        </class>
    </xsl:template>

    <xsl:template match="Foundation.Core.Interface" mode="psm">
        <xsl:variable name="element_name" select="Foundation.Core.ModelElement.name"/>
        <interface name="{$element_name}">
            <xsl:apply-templates mode="psm-supertypes"
                                 select="Foundation.Core.GeneralizableElement.generalization/Foundation.Core.Generalization"/>
            <xsl:apply-templates mode="psm-operations"
                                 select="Foundation.Core.Classifier.feature/Foundation.Core.Operation"/>
        </interface>
    </xsl:template>

    <xsl:template match="Foundation.Core.Abstraction" mode="psm-specifications">
        <xsl:variable name="abstraction" select="key('abstraction', ./@xmi.idref)"/>
        <xsl:variable name="target" select="$abstraction/Foundation.Core.Dependency.supplier/*/@xmi.idref"/>
        <implements>
            <xsl:call-template name="classify">
                <xsl:with-param name="target" select="$target"/>
            </xsl:call-template>
        </implements>
    </xsl:template>

    <xsl:template match="Foundation.Core.Generalization" mode="psm-supertypes">
        <xsl:variable name="generalization" select="key('generalization', ./@xmi.idref)"/>
        <xsl:variable name="target" select="$generalization/Foundation.Core.Generalization.parent/*/@xmi.idref"/>
        <extends>
            <xsl:call-template name="classify">
                <xsl:with-param name="target" select="$target"/>
            </xsl:call-template>
        </extends>
    </xsl:template>

    <xsl:template match="Foundation.Core.Attribute" mode="psm-attributes">
        <attribute visibility="{Foundation.Core.ModelElement.visibility/@xmi.value}"
                   name="{Foundation.Core.ModelElement.name}">
            <xsl:call-template name="classify">
                <xsl:with-param name="target" select="Foundation.Core.StructuralFeature.type/*/@xmi.idref"/>
            </xsl:call-template>
        </attribute>
    </xsl:template>

    <xsl:template match="Foundation.Core.Operation" mode="psm-operations">
        <xsl:variable name="target"
                      select="Foundation.Core.BehavioralFeature.parameter/
                 Foundation.Core.Parameter[Foundation.Core.Parameter.kind/@xmi.value='return']/
                 Foundation.Core.Parameter.type/*/@xmi.idref"/>

        <operation visibility="{Foundation.Core.ModelElement.visibility/@xmi.value}"
                   name="{Foundation.Core.ModelElement.name}">
            <xsl:choose>
                <xsl:when test="$target">
                    <xsl:call-template name="classify">
                        <xsl:with-param name="target" select="$target"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="typename">void</xsl:attribute>
                    <xsl:attribute name="metatype">primitive</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:apply-templates select="Foundation.Core.BehavioralFeature.parameter/
                                     Foundation.Core.Parameter[Foundation.Core.Parameter.kind/@xmi.value!='return']"/>
        </operation>
    </xsl:template>

    <xsl:template match="Foundation.Core.Parameter">
        <xsl:variable name="target" select="Foundation.Core.Parameter.type/*/@xmi.idref"/>
        <parameter name="{Foundation.Core.ModelElement.name}">
            <xsl:call-template name="classify">
                <xsl:with-param name="target" select="$target"/>
            </xsl:call-template>
        </parameter>
    </xsl:template>

    <xsl:template name="classify">
        <xsl:param name="target"/>
        <xsl:variable name="classifier" select="key('classifier', $target)"/>
        <xsl:variable name="classifier_name" select="$classifier/Foundation.Core.ModelElement.name"/>
        <xsl:attribute name="typename">
            <xsl:value-of select="$classifier_name"/>
        </xsl:attribute>
        <xsl:attribute name="metatype">
            <xsl:choose>
                <xsl:when test="name($classifier)='Foundation.Core.Class'">class</xsl:when>
                <xsl:when test="name($classifier)='Foundation.Core.Interface'">interface</xsl:when>
                <xsl:when test="name($classifier)='Foundation.Core.DataType'">primitive</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="name($classifier)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="Foundation.Core.AssociationEnd" mode="psm-associations">
        <association>
            <xsl:variable name="rolename" select="Foundation.Core.ModelElement.name"/>
            <xsl:if test="string-length($rolename) > 0">
                <xsl:attribute name="role"><xsl:value-of select="$rolename"/></xsl:attribute>
            </xsl:if>
            <xsl:variable name="visibility" select="Foundation.Core.ModelElement.visibility"/>
            <xsl:if test="string-length($visibility) > 0">
                <xsl:attribute name="visibility"><xsl:value-of select="$visibility"/></xsl:attribute>
            </xsl:if>

            <xsl:variable name="navigable" select="Foundation.Core.AssociationEnd.isNavigable/@xmi.value"/>
            <xsl:if test="string-length($navigable) > 0">
                <xsl:attribute name="navigable"><xsl:value-of select="$navigable"/></xsl:attribute>
            </xsl:if>
            <xsl:variable name="ordering" select="Foundation.Core.AssociationEnd.ordering/@xmi.value"/>
            <xsl:if test="string-length($ordering) > 0">
                <xsl:attribute name="ordering"><xsl:value-of select="$ordering"/></xsl:attribute>
            </xsl:if>

            <xsl:variable name="target" select="Foundation.Core.AssociationEnd.type/*/@xmi.idref"/>
            <xsl:call-template name="classify">
                <xsl:with-param name="target" select="$target"/>
            </xsl:call-template>

            <xsl:apply-templates select=".//Foundation.Data_Types.Multiplicity"/>
        </association>
    </xsl:template>

    <xsl:template match="Foundation.Data_Types.Multiplicity[@xmi.idref]">
        <xsl:apply-templates select="key('multiplicity', @xmi.idref)"/>
    </xsl:template>
    <xsl:template match="Foundation.Data_Types.Multiplicity[@xmi.id]">
        <xsl:attribute name="minoccurs"><xsl:value-of select="normalize-space(.//Foundation.Data_Types.MultiplicityRange.lower)"/></xsl:attribute>
        <xsl:attribute name="maxoccurs"><xsl:value-of select="normalize-space(.//Foundation.Data_Types.MultiplicityRange.upper)"/></xsl:attribute>
    </xsl:template>

</xsl:stylesheet>
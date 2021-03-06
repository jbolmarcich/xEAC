<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:res="http://www.w3.org/2005/sparql-results#" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xeac="https://github.com/ewg118/xEAC" exclude-result-prefixes="#all" version="2.0">

	<xsl:template name="xeac:queryNomisma">
		<xsl:param name="uri"/>

		<xsl:variable name="endpoint">http://nomisma.org/query</xsl:variable>

		<xsl:variable name="query">
			<![CDATA[PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:  <http://purl.org/dc/terms/>
PREFIX nm:       <http://nomisma.org/id/>			
PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?object ?title ?identifier ?collection ?obvThumb ?revThumb WHERE {
{?type ?p <URI>.
?object nm:type_series_item ?type.
?object a nm:coin.
?object dcterms:title ?title.
OPTIONAL { ?object nm:collection ?colUri .
?colUri skos:prefLabel ?collection 
FILTER(langMatches(lang(?collection), "EN"))}
?object nm:obverse ?obverse .
?obverse foaf:thumbnail ?obvThumb .
?object nm:reverse ?reverse .
?reverse foaf:thumbnail ?revThumb.
OPTIONAL { ?object dcterms:identifier ?identifier }}
UNION {?object ?p <URI>.
?object a nm:coin.
?object dcterms:title ?title.
OPTIONAL { ?object nm:collection ?colUri .
?colUri skos:prefLabel ?collection 
FILTER(langMatches(lang(?collection), "EN"))}
?object nm:obverse ?obverse .
?obverse foaf:thumbnail ?obvThumb .
?object nm:reverse ?reverse .
?reverse foaf:thumbnail ?revThumb.
OPTIONAL { ?object dcterms:identifier ?identifier }}
} LIMIT 5]]>
		</xsl:variable>
		<xsl:variable name="service" select="concat($endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'URI', $uri))), '&amp;output=xml')"/>

		<xsl:apply-templates select="document($service)/res:sparql" mode="queryNomisma"/>
	</xsl:template>

	<xsl:template match="res:sparql" mode="queryNomisma">
		<xsl:if test="count(descendant::res:result) &gt; 0">
			<div class="objects">
				<h3>Related objects in Nomisma</h3>

				<!-- choose between between Metis (preferred) or internal links -->
				<xsl:apply-templates select="descendant::res:result" mode="queryNomisma"/>
			</div>
		</xsl:if>
	</xsl:template>

	<xsl:template match="res:result" mode="queryNomisma">
		<div class="g_doc">
			<a href="{res:binding[@name='object']/res:uri}" title="{concat(res:binding[@name='collection']/res:literal, ': ', res:binding[@name='identifier']/res:literal)}">
				<img class="gi" src="{res:binding[@name='revThumb']/res:uri}"/>
				<img class="gi" src="{res:binding[@name='obvThumb']/res:uri}"/>
			</a>
		</div>
	</xsl:template>

	<xsl:template name="xeac:relatedResources">
		<xsl:param name="uri"/>
		<xsl:param name="endpoint"/>

		<xsl:variable name="query">
			<![CDATA[ PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:  <http://purl.org/dc/terms/>
PREFIX foaf:  <http://xmlns.com/foaf/0.1/>
SELECT ?uri ?role ?title ?abstract ?thumbnail WHERE {
?uri ?role <URI> ;
dcterms:title ?title
OPTIONAL {?uri dcterms:abstract ?abstract}
OPTIONAL {?uri foaf:thumbnail ?thumbnail}} ORDER BY ASC(?role)]]>
		</xsl:variable>
		<xsl:variable name="service" select="concat($endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'URI', $uri))), '&amp;output=xml')"/>

		<xsl:apply-templates select="document($service)/res:sparql[count(descendant::res:result) &gt; 0]" mode="relatedResources"/>
	</xsl:template>

	<xsl:template match="res:sparql" mode="relatedResources">
		<xsl:variable name="objects" select="distinct-values(descendant::res:result/res:binding[@name='uri']/res:uri)"/>
		<xsl:variable name="results" as="element()*">
			<xsl:copy-of select="res:results"/>
		</xsl:variable>
		
		<div>
			<h3>Related Resources</h3>
			<xsl:for-each select="$objects">
				<xsl:variable name="uri" select="."/>
				<xsl:variable name="roles" select="$results/res:result[res:binding[@name='uri']/res:uri = $uri]/res:binding[@name='role']/res:uri"/>
				<xsl:apply-templates select="$results/res:result[res:binding[@name='uri']/res:uri = $uri][1]" mode="relatedResources">
					<xsl:with-param name="roles" select="$roles"/>
					<xsl:with-param name="position" select="position()"/>
				</xsl:apply-templates>
			</xsl:for-each>			
		</div>
	</xsl:template>

	<xsl:template match="res:result" mode="relatedResources">
		<xsl:param name="roles"/>
		<xsl:param name="position"/>
		
		<div class="row">
			<div class="col-md-8">
				<h4>
					<xsl:value-of select="$position"/>
					<xsl:text>. </xsl:text>
					<a href="{res:binding[@name='uri']/res:uri}">
						<xsl:value-of select="res:binding[@name='title']/res:literal"/>
					</a>
				</h4>
				<dl class="dl-horizontal">
					<dt>Relation</dt>
					<dd>
						<xsl:for-each select="$roles">
							<a href="{.}">
								<xsl:value-of select="xeac:normalize_property(.)"/>
							</a>
							<xsl:if test="not(position()=last())">
								<xsl:text>, </xsl:text>
							</xsl:if>
						</xsl:for-each>
						
					</dd>
					<xsl:if test="res:binding[@name='abstract']/res:literal">
						<dt>Abstract</dt>
						<dd>
							<xsl:value-of select="res:binding[@name='abstract']/res:literal"/>
						</dd>
					</xsl:if>
				</dl>
			</div>
			<div class="col-md-4 text-right">
				<xsl:if test="res:binding[@name='thumbnail']/res:uri">
					<a href="{res:binding[@name='uri']/res:uri}">
						<img src="{res:binding[@name='thumbnail']/res:uri}" alt="thumbnail"/>
					</a>
				</xsl:if>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>

<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bgf="http://planet-sl.org/bgf" xmlns:xbgf="http://planet-sl.org/xbgf" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:import href="bgf2xhtml.xslt"/>
	<xsl:output method="html" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
	<xsl:param name="date"/>
	<xsl:param name="fname"/>
	<xsl:param name="fullpath"/>
	<xsl:template match="/xbgf:sequence">
		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
			<head>
				<title>Browsable Grammar Transformation</title>
				<link href="/slps.css" rel="stylesheet" type="text/css"/>
				<script type="text/javascript">
					<xsl:text>

				  var _gaq = _gaq || [];
				  _gaq.push(['_setAccount', 'UA-3743366-7']);
				  _gaq.push(['_setDomainName', 'github.com']);
				  _gaq.push(['_trackPageview']);

				  (function() {
				    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
				    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
				    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
				  })();

				</xsl:text>
				</script>
			</head>
			<body>
				<h1>
					<xsl:value-of select="$fname"/>
				</h1>
				<h2 class="src">
					<xsl:text>Source: </xsl:text>
					<a href="http://github.com/grammarware/slps/blob/master/{substring-after($fullpath,'/slps/')}">SLPS/<xsl:value-of select="substring-after($fullpath,'/slps/')"/></a>
				</h2>
				<ul>
					<xsl:for-each select="./xbgf:*">
						<li>
							<xsl:apply-templates select="."/>
						</li>
					</xsl:for-each>
				</ul>
				<hr/>
				<div class="b">
					<xsl:text>Maintained by Dr. </xsl:text>
					<a href="http://grammarware.net/">Vadim Zaytsev</a>
					<xsl:text> a.k.a. @</xsl:text>
					<a href="http://github.com/grammarware">grammarware</a>
					<xsl:text>.
Last updated: </xsl:text>
					<xsl:value-of select="$date"/>
					<xsl:text>.</xsl:text>
				</div>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="xbgf:atomic">
		<ul xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
			<xsl:for-each select="./xbgf:*">
				<li>
					<xsl:apply-templates select="."/>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:template>
	<!-- optional context -->
	<xsl:template name="context">
		<xsl:param name="in"/>
		<xsl:choose>
			<xsl:when test="$in/nonterminal">
				<span xmlns="http://www.w3.org/1999/xhtml" class="meta">
					<xsl:text> in </xsl:text>
				</span>
				<xsl:call-template name="linknt">
					<xsl:with-param name="nt" select="$in/nonterminal"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$in/label">
				<span xmlns="http://www.w3.org/1999/xhtml" class="meta">
					<xsl:text> in </xsl:text>
				</span>
				<xsl:call-template name="linklabel">
					<xsl:with-param name="l" select="$in/label"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!-- chain, define, ... -->
	<xsl:template match="xbgf:*">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:text>
</xsl:text>
		<xsl:for-each select="./bgf:production">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select="."/>
		</xsl:for-each>
		<xsl:call-template name="context">
			<xsl:with-param name="in" select="./in"/>
		</xsl:call-template>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:add|xbgf:remove">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd">
				<xsl:choose>
					<xsl:when test="local-name() = 'add' and ./vertical">
						<xsl:text>addV</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'add' and ./horizontal">
						<xsl:text>addH</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'remove' and ./vertical">
						<xsl:text>removeV</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'remove' and ./horizontal">
						<xsl:text>removeH</xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:text>
 </xsl:text>
		<xsl:apply-templates select="./*/bgf:production"/>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:inline">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="text()"/>
		</xsl:call-template>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:undefine">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="nonterminal[1]/text()"/>
		</xsl:call-template>
		<xsl:for-each select="nonterminal[position()&gt;1]">
			<xsl:text>, </xsl:text>
			<xsl:call-template name="linknt">
				<xsl:with-param name="nt" select="text()"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>);
	</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:deyaccify|xbgf:eliminate|xbgf:horizontal">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="nonterminal/text()"/>
		</xsl:call-template>
		<xsl:text>);
		</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:unlabel">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linklabel">
			<xsl:with-param name="l" select="label"/>
		</xsl:call-template>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:distribute|xbgf:vertical">
		<xsl:element name="a" namespace="http://www.w3.org/1999/xhtml">
			<xsl:attribute name="class">
				<xsl:text>cmd</xsl:text>
			</xsl:attribute>
			<xsl:attribute name="href">
				<xsl:text>#</xsl:text>
				<xsl:value-of select="local-name()"/>
			</xsl:attribute>
			<xsl:value-of select="local-name()"/>
		</xsl:element>
		<xsl:text>(</xsl:text>
		<xsl:call-template name="context">
			<xsl:with-param name="in" select="."/>
		</xsl:call-template>
		<xsl:text> );
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:factor|xbgf:massage|xbgf:narrow|xbgf:replace|xbgf:widen">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:text>
 </xsl:text>
		<xsl:apply-templates select="bgf:expression[1]"/>
		<xsl:text>,
 </xsl:text>
		<xsl:apply-templates select="bgf:expression[2]"/>
		<xsl:choose>
			<xsl:when test="in">
				<xsl:text>
</xsl:text>
				<xsl:call-template name="context">
					<xsl:with-param name="in" select="./in"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:fold|xbgf:unfold">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="./nonterminal"/>
		</xsl:call-template>
		<xsl:choose>
			<xsl:when test="in">
				<xsl:call-template name="context">
					<xsl:with-param name="in" select="./in"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:rename">
		<xsl:choose>
			<xsl:when test="local-name(*) = 'label'">
				<xsl:call-template name="linkcmd">
					<xsl:with-param name="cmd">
						<xsl:text>renameL</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="linklabel">
					<xsl:with-param name="l" select="label/from"/>
				</xsl:call-template>
				<xsl:text>, </xsl:text>
				<xsl:call-template name="displaylabel">
					<xsl:with-param name="l" select="label/to"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="local-name(*) = 'nonterminal'">
				<xsl:call-template name="linkcmd">
					<xsl:with-param name="cmd">
						<xsl:text>renameN</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="linknt">
					<xsl:with-param name="nt" select="nonterminal/from"/>
				</xsl:call-template>
				<xsl:text>, </xsl:text>
				<xsl:call-template name="displaynt">
					<xsl:with-param name="nt" select="nonterminal/to"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="local-name(*) = 'selector'">
				<xsl:call-template name="linkcmd">
					<xsl:with-param name="cmd">
						<xsl:text>renameS</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<span xmlns="http://www.w3.org/1999/xhtml" class="sel">
					<xsl:apply-templates select="selector/from"/>
				</span>
				<xsl:text>, </xsl:text>
				<span xmlns="http://www.w3.org/1999/xhtml" class="sel">
					<xsl:apply-templates select="selector/to"/>
				</span>
			</xsl:when>
			<xsl:when test="local-name(*) = 'terminal'">
				<xsl:call-template name="linkcmd">
					<xsl:with-param name="cmd">
						<xsl:text>renameT</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="displayt">
					<xsl:with-param name="t" select="terminal/from"/>
				</xsl:call-template>
				<xsl:text>, </xsl:text>
				<xsl:call-template name="displayt">
					<xsl:with-param name="t" select="terminal/to"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="local-name()"/>
				<xsl:text>-</xsl:text>
				<xsl:value-of select="local-name(*)"/>
				<xsl:text>(</xsl:text>
				<xsl:apply-templates select="./*/*[1]"/>
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="./*/*[2]"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:reroot">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="./root[1]"/>
		</xsl:call-template>
		<xsl:for-each select="./root[position()&gt;1]">
			<xsl:text>, </xsl:text>
			<xsl:call-template name="linknt">
				<xsl:with-param name="nt" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:strip">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:choose>
			<xsl:when test="label">
				<xsl:text>[</xsl:text>
				<xsl:value-of select="*/text()"/>
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:when test="selector">
				<xsl:value-of select="*/text()"/>
				<xsl:text>::</xsl:text>
			</xsl:when>
			<xsl:when test="terminal">
				<xsl:value-of select="local-name(*)"/>
				<xsl:text>, "</xsl:text>
				<xsl:value-of select="*/text()"/>
				<xsl:text>"</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="local-name(*)"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template match="xbgf:unite">
		<xsl:call-template name="linkcmd">
			<xsl:with-param name="cmd" select="local-name()"/>
		</xsl:call-template>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="add/text()"/>
		</xsl:call-template>
		<xsl:text>, </xsl:text>
		<xsl:call-template name="linknt">
			<xsl:with-param name="nt" select="to/text()"/>
		</xsl:call-template>
		<xsl:text>);
</xsl:text>
	</xsl:template>
	<xsl:template name="linkcmd">
		<xsl:param name="cmd"/>
		<a xmlns="http://www.w3.org/1999/xhtml" class="cmd" href="http://slps.github.com/xbgf/#{$cmd}">
			<xsl:value-of select="$cmd"/>
		</a>
		<xsl:text> (</xsl:text>
	</xsl:template>
	<xsl:template name="linklabel">
		<xsl:param name="l"/>
		<xsl:text>[</xsl:text>
		<a xmlns="http://www.w3.org/1999/xhtml" class="label" href="{$gname}#{$l}">
			<xsl:value-of select="$l"/>
		</a>
		<xsl:text>]</xsl:text>
	</xsl:template>
	<!-- We need override the standard BGF2HTML one in order to hyperlink the nonterminal that is being defined. -->
	<xsl:template match="bgf:production">
		<xsl:if test="./label">
			<xsl:call-template name="displaylabel">
				<xsl:with-param name="l" select="label"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:apply-templates select="nonterminal"/>
		<xsl:text>:</xsl:text>
		<xsl:choose>
			<xsl:when test="./bgf:expression/choice">
				<xsl:for-each select="./bgf:expression/choice/bgf:expression">
					<xsl:text>
	        </xsl:text>
					<xsl:call-template name="no-parenthesis">
						<xsl:with-param name="expr" select="."/>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:text>
	</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>
	        </xsl:text>
				<xsl:call-template name="no-parenthesis">
					<xsl:with-param name="expr" select="./bgf:expression"/>
				</xsl:call-template>
				<xsl:text>
	</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>

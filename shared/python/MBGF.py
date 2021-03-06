#!/Library/Frameworks/Python.framework/Versions/3.1/bin/python3
import os, sys
sys.path.append(os.getcwd().split('slps')[0]+'slps/shared/python')
import slpsns, BGF3
import xml.etree.ElementTree as ET

cx = {}

class TopModel:
	def getData(self, id):
		if id in self.data.keys():
			return self.data[id]
		else:
			return None
	def who(self):
		return self.__class__.__name__
	def parsebasic(self, xml):
		global cx
		if 'id' in xml.attrib:
			self.id = xml.attrib['id']
		else:
			if self.who() in cx:
				cx[self.who()] += 1
			else:
				cx[self.who()] = 1
			self.id = self.who()+str(cx[self.who()])
		if 'depends' in xml.attrib:
			self.depends = xml.attrib['depends']
		else:
			self.depends = ''
		if 'blocks' in xml.attrib:
			self.blocks = xml.attrib['blocks']
		else:
			self.blocks = ''
		self.data = {}
		self.ids = {}

class SrcSimpleModel (TopModel):
	def parse(self, xml):
		self.parsebasic(xml)
		for ss in xml.findall('state'):
			for s in ss.attrib['src'].split(','):
				self.data[s] = ss.text
				if 'id' in ss.attrib:
					self.ids[s] = ss.attrib['id']

class SrcProdModel (TopModel):
	def getNTs(self,id):
		nts = []
		for p in self.getProds(id):
			if p.nt not in nts:
				nts.append(p.nt)
		return nts
	def getProds(self,id):
		if id in self.data.keys():
			return self.data[id][0]
		else:
			return []
	def getScope(self,id):
		if id in self.data.keys():
			return self.data[id][1]
		else:
			return []
	def getData(self, id):
		if id in self.data.keys():
			return '; '.join(map(str,self.data[id][0])).replace(':\n        ',' ← ').replace('\n        ',' | ')
		else:
			return '∅'
	def parse(self, xml):
		self.parsebasic(xml)
		for ss in xml.findall('state'):
			for s in ss.attrib['src'].split(','):
				self.data[s] = [[],[]]
				for p in ss.findall(slpsns.bgf_('production')):
					xp = BGF3.Production()
					xp.parse(p)
					self.data[s][0].append(xp)
				self.data[s][1] = ss.findall('in/*')

#
# <sources>
# 	<src name="dcg">snapshot/dcg.bgf</src>
# 	<src name="sdf">snapshot/sdf.bgf</src>
# 	<src name="rsc">snapshot/rascal.bgf</src>
# </sources>
class Sources (SrcSimpleModel):
	def __init__(self, xml):
		self.parsebasic(xml)
		for s in xml.findall('src'):
			self.data[s.attrib['name']] = s.text

# <naming-convention>
# 	<default>l!</default>
# 	<src name="dcg">l!</src>
# 	<src name="sdf,rsc">C!</src>
# </naming-convention>
class NamingConvention (SrcSimpleModel):
	def __init__(self, xml):
		self.default = xml.findtext('default')
		self.parse(xml)
	def getSpecifics(self):
		return self.default
	
# <name-bind>
# 	<name>function</name>
# 	<src name="dcg">function</src>
# 	<src name="sdf,rsc">Function</src>
# </name-bind>
class NameBind (SrcSimpleModel):
	def __init__(self, xml):
		self.nt = xml.findtext('name')
		self.parse(xml)
	def getSpecifics(self):
		return self.nt
	

# <width>
# 	<bgf:expression>
# 		<nonterminal>newline</nonterminal>
# 	</bgf:expression>
# 	<src name="dcg,sdf">+</src>
# 	<src name="rsc">!</src>
# 	<in>
# 		<nonterminal>function</nonterminal>
# 	</in>
# </width>
class Width (SrcSimpleModel):
	def __init__(self, xml):
		self.expr = BGF3.Expression([])
		self.expr.parse(xml.findall(slpsns.bgf_('expression'))[0])
		# apply namemap!!!
		self.parse(xml)
		self.scope = xml.findall('in')
	def getSpecifics(self):
		return str(self.expr)	

# <unification>
# 	<name>expr</name>
# 	<src name="dcg" labels="apply,binary">
# 		<bgf:production>
#		...
# 		</bgf:production>
# 	</src>
# </unification>
class Unification (SrcProdModel):
	def __init__(self, xml):
		self.nt = xml.findtext('name')
		self.parse(xml)
	def getSpecifics(self):
		return 'n('+self.nt+')'

# <iteration>
# 	<label>binary</label>
# 	<name>expr</name>
# 	<separator>ops</separator>
# 	<src name="dcg">iterate</src>
# 	<src name="sdf,rsc">lassoc</src>
# </iteration>
class Iteration (SrcSimpleModel):
	def __init__(self, xml):
		self.label = xml.findtext('label')
		if not self.label:
			self.label = ''
		self.nt = xml.findtext('name')
		self.sep = xml.findtext('separator')
		self.parse(xml)
	def getSpecifics(self):
		s = ''
		if self.label:
			s += '['+self.label+'], '
		s += 'n('+self.nt+')'
		if self.sep:
			s += ', n('+self.sep+')'
		return s

# <selectables>
# 	<src name="...">
# 		<bgf:production>
# 			...
# 			<marked>
# 			...
# 			</marked>
# 			...
# 		</bgf:production>
# 	</src>
# </selectables>
class Selectables (SrcProdModel):
	def __init__(self, xml):
		self.parse(xml)
	def getSpecifics(self):
		return '—'

# <production-label>
# 	<src name="...">
# 		<bgf:production>
#			<label>...</label>
# 			...
# 		</bgf:production>
# 	</src>
# </production-label>
class ProdLabel (SrcProdModel):
	def __init__(self, xml):
		self.parse(xml)
	def getSpecifics(self):
		return '—'

# <top-choice>
# 	<name>ops</name>
# 	<src name="ant">horizontal</src>
# 	<src name="dcg,sdf,rsc">vertical</src>
# </top-choice>
class TopChoice (SrcSimpleModel):
	def __init__(self, xml):
		self.nt = xml.findtext('name')
		self.parse(xml)
	def getSpecifics(self):
		return 'n('+self.nt+')'

# <folding>
# 	<name>apply</name>
# 	<src name="ant">
# 		<bgf:production>
# 		...
# 		</bgf:production>
# 	</src>
# </folding>
class Folding (SrcProdModel):
	def __init__(self, xml):
		self.nt = xml.findtext('state/'+slpsns.bgf_('production')+'/nonterminal')
		self.parse(xml)
	def getSpecifics(self):
		return 'n('+self.nt+')'

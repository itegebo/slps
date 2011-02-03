#!/usr/local/bin/python
# -*- coding: utf-8 -*-
import os, sys, math
import slpsns
import elementtree.ElementTree as ET
import BGF

######################################################################
##########                     Size metrics                 ##########
######################################################################
# TERM - number of terminal symbols in the grammar
def TERM(g):
	return len(term(g))
def term(g):
	ts = []
	for p in g.prods:
		for n in p.expr.wrapped.getXml().findall('.//terminal'):
			if n.text not in ts:
				ts.append(n.text)
	return ts

# VAR - number of nonterminal symbols in the grammar
def VAR(g):
	return len(var(g))
def var(g):
	nts = []
	for p in g.prods:
		if p.nt not in nts:
			nts.append(p.nt)
		for n in p.expr.wrapped.getXml().findall('.//nonterminal'):
			if n.text not in nts:
				nts.append(n.text)
	return nts

# VAL - number of values utilised in the grammar
def VAL(g):
	return len(val(g))
def val(g):
	vals = []
	for v in g.getXml().findall('.//value'):
		if v.text not in vals:
			vals.append(v.text)
	return vals

# LABS - number of production labels and expression selectors used in the grammar
def LAB(g):
	return len(lab(g))
def lab(g):
	# returns the number of production labels used in the grammar
	labs = []
	for v in g.prods:
		if v.label and v.label not in labs:
			labs.append(v.label)
	for v in g.getXml().findall('.//selectable'):
		if v.findtext('selector') not in labs:
			labs.append(v.findtext('selector'))
	return labs

# USED - number of nonterminal symbols used in the grammar
def USED(g):
	return len(used(g))
def used(g):
	nts = []
	for p in g.prods:
		for n in p.expr.wrapped.getXml().findall('.//nonterminal'):
			if n.text not in nts:
				nts.append(n.text)
	return nts

# DEFD - number of nonterminal symbols defined by the grammar 
def DEFD(g):
	return len(defd(g))
def defd(g):
	nts = []
	for p in g.prods:
		if p.nt not in nts:
			nts.append(p.nt)
	return nts

# TOP - number of top (defined but not used) nonterminal symbols in the grammar
def TOP(g):
	return len(top(g))
def top(g):
	tops = []
	usednts = used(g)
	for nt in defd(g):
		if nt not in usednts:
			tops.append(nt)
	return tops

# BOT - number of bottom (used but not defined) nonterminal symbols in the grammar
def BOT(g):
	return len(bot(g))
def bot(g):
	bottoms = []
	definednts = defd(g)
	for nt in used(g):
		if nt not in definednts:
			bottoms.append(nt)
	return bottoms

# BPROD - number of productions in the grammar (storage point of view)
def BPROD(g):
	return len(g.prods)

# PROD - number of productions in the grammar (classic point of view)
def PROD(g):
	prod = 0
	for p in g.prods:
		if p.expr.wrapped.__class__.__name__ == 'Choice':
			prod += len(p.expr.wrapped.data)
		else:
			prod += 1
	return prod

######################################################################
##########               Structural metrics                 ##########
######################################################################
# first some general functions for internal use
def getADigraph(g):
	calls = getCallGraph(g)
	levels = getLevels(g)
	adg = []
	for i in range(0,len(levels)):
		adg.append([])
		for j in range(0,len(levels)):
			if i == j:
				# to ensure acyclicity
				continue
			for n in levels[i]:
				for m in levels[j]:
					if m in calls[n] and j not in adg[i]:
						adg[i].append(j)
	return adg

def getLevels(g):
	calls = getCallGraph(g)
	calls = getClosure(calls)
	unassigned = calls.keys()
	levels = []
	while len(unassigned)>0:
		nt = unassigned[0]
		levels.append([])
		levels[-1].append(nt)
		unassigned = unassigned[1:]
		for n in calls[nt]:
			if nt in calls[n]:
				levels[-1].append(n)
				if n in unassigned:
					unassigned.remove(n)
	return levels

def getCallGraph(g):
	calls = {}
	for p in g.prods:
		if p.nt not in calls.keys():
			calls[p.nt] = []
		for n in p.expr.wrapped.getXml().findall('.//nonterminal'):
			if n.text not in calls[p.nt]:
				calls[p.nt].append(n.text)
			if n.text not in calls.keys():
				calls[n.text] = []
	#for n in calls.keys():
	#	print n,'▻',calls[n]
	#print '--------------------'
	return calls

def getClosure(cg):
	calls = cg.copy()
	for n in calls.keys():
		for x in calls[n]:
			if x not in calls.keys():
				calls[x] = []
			for y in calls[x]:
				if y not in calls[n]:
					calls[n].append(y)
		calls[n].sort()
	#for n in calls.keys():
	#	print n,'▻*',calls[n]
	#print '--------------------'
	return calls

# DEP - cardinality of the largest grammatical level
def DEP(g):
	return max(map(len,getLevels(g)))

# LEV - number of grammatical levels
def LEV(g):
	return len(getLevels(g))

# CLEV - number of grammatical levels normalised by the number of nonterminals
def CLEV(g):
	return 100*LEV(g)/(0.0+VAR(g))

# RLEV - number of recursive grammatical levels
def RLEV(g):
	cg = getCallGraph(g)
	return len(filter(lambda x:(len(x)>1)or(x[0] in cg[x[0]]),getLevels(g)))

# NLEV - number of non-trivial grammatical levels
def NLEV(g):
	cg = getCallGraph(g)
	return len(filter(lambda x:len(x)>1,getLevels(g)))

# HEI - the longest chain of grammatical levels in their ordered directed graph
def longest(n,adg):
	if len(adg[n])==0:
		return 0
	else:
		paths = []
		for x in adg[n]:
			paths.append(1+longest(x,adg))
		return max(paths)

def HEI(g):
	adg = getADigraph(g)
	paths = []
	for i in range(0,len(adg)):
		paths.append(longest(i,adg))
	return max(paths)

# TIMP - tree impurity
def TIMP(g):
	cg = getClosure(getCallGraph(g))
	n = len(cg)
	e = sum(map(len,cg.values()))
	# Power and Malloy made two mistakes:
	# (1) the number of edges in a complete directed graph is n(n-1), not n(n-1)/2, as in a complete undirected graph!
	# (2) we don't have to substract another 1 from the number of nonterminals to account for a start symbol
	# To compute TIMP exactly as they intended to, run this:
	# return (100*2*(e-n+1)/(0.0+(n-1)*(n-2)))
	# To run our fixed version, uncomment this:
	return (100*(e-n+1)/(0.0+n*(n-1)))

######################################################################
##########               Complexity metrics                 ##########
######################################################################
# MCC - McCabe cyclomatic complexity
def mccabe(node):
	if node.__class__.__name__ in ('Production','Selectable'):
		return mccabe(node.expr)
	elif node.__class__.__name__ == 'Expression':
		return mccabe(node.wrapped)
	elif node.__class__.__name__ == 'Marked':
		return mccabe(node.data)
	elif node.__class__.__name__ in ('Plus','Star','Optional'):
		return 1+mccabe(node.data)
	elif node.__class__.__name__ in ('Terminal','Nonterminal','Epsilon','Any','Empty','Value'):
		return 0
	elif node.__class__.__name__ == 'Choice':
		return len(node.data)-1 + max(map(mccabe,node.data))
	elif node.__class__.__name__ == 'Sequence':
		return sum(map(mccabe,node.data))
	else:
		print 'How to deal with',node.__class__.__name__,'?'
		return 0

def MCC(g):
	# classic part
	usual = sum(map(mccabe,g.prods))
	# account for the grammar having multiple productions per nonterminal
	alt = 0
	passed = []
	for p in g.prods:
		if p.nt in passed:
			alt += 1
		else:
			passed.append(p.nt)
	return usual + alt

# AVS - average size of the right hand side of grammar productions
def rhssize(node):
	if node.__class__.__name__ in ('Production','Selectable'):
		return rhssize(node.expr)
	elif node.__class__.__name__ == 'Expression':
		return rhssize(node.wrapped)
	elif node.__class__.__name__ == 'Marked':
		return rhssize(node.data)
	elif node.__class__.__name__ in ('Plus','Star','Optional'):
		return rhssize(node.data)
	elif node.__class__.__name__ in ('Terminal','Nonterminal','Value'):
		return 1
	elif node.__class__.__name__ in ('Epsilon','Any','Empty'):
		return 0
	elif node.__class__.__name__ in ('Choice','Sequence'):
		return sum(map(rhssize,node.data))
	else:
		print 'How to deal with',node.__class__.__name__,'?'
		return 0

def AVS(g):
	return sum(map(rhssize,g.prods))/(0.0+VAR(g))

# HAL - Halstead effort
def opr(node):
	# number of occurrences of operators
	if node.__class__.__name__ == 'Grammar':
		return sum(map(opr,node.prods))
	elif node.__class__.__name__ == 'Production':
		return opr(node.expr)
	elif node.__class__.__name__ == 'Selectable':
		return 1+opr(node.expr)
	elif node.__class__.__name__ == 'Expression':
		return opr(node.wrapped)
	elif node.__class__.__name__ == 'Marked':
		return 1+opr(node.data)
	elif node.__class__.__name__ in ('Plus','Star','Optional'):
		return 1+opr(node.data)
	elif node.__class__.__name__ in ('Terminal','Nonterminal','Value'):
		return 0
	elif node.__class__.__name__ in ('Epsilon','Any','Empty'):
		return 1
	elif node.__class__.__name__ in ('Choice','Sequence'):
		return sum(map(opr,node.data))
	else:
		print 'How to deal with',node.__class__.__name__,'?'
		return 0
		
def opd(node):
	# number of occurrences of operands
	if node.__class__.__name__ == 'Grammar':
		return sum(map(opd,node.prods))
	elif node.__class__.__name__ == 'Production':
		if node.label:
			return 2+opd(node.expr)
		else:
			return 1+opd(node.expr)
	elif node.__class__.__name__ == 'Selectable':
		return 1+opd(node.expr)
	elif node.__class__.__name__ == 'Expression':
		return opd(node.wrapped)
	elif node.__class__.__name__ == 'Marked':
		return opd(node.data)
	elif node.__class__.__name__ in ('Plus','Star','Optional'):
		return opd(node.data)
	elif node.__class__.__name__ in ('Terminal','Nonterminal','Value'):
		return 1
	elif node.__class__.__name__ in ('Epsilon','Any','Empty'):
		return 0
	elif node.__class__.__name__ in ('Choice','Sequence'):
		return sum(map(opd,node.data))
	else:
		print 'How to deal with',node.__class__.__name__,'?'
		return 0

def union(a,b):
	c = a[:]
	for x in b:
		if x not in c:
	 		c.append(x)
	return c

def allOperators(node):
	if node.__class__.__name__ == 'Grammar':
		return reduce(union,map(allOperators,node.prods),[])
	elif node.__class__.__name__ == 'Production':
		return allOperators(node.expr)
	elif node.__class__.__name__ == 'Selectable':
		return union(allOperators(node.expr),node.__class__.__name__)
	elif node.__class__.__name__ == 'Expression':
		return allOperators(node.wrapped)
	elif node.__class__.__name__ in ('Plus','Star','Optional','Marked'):
		return union(allOperators(node.data),node.__class__.__name__)
	elif node.__class__.__name__ in ('Terminal','Nonterminal','Value'):
		return []
	elif node.__class__.__name__ in ('Epsilon','Any','Empty'):
		return [node.__class__.__name__]
	elif node.__class__.__name__ in ('Choice','Sequence'):
		return reduce(union,map(allOperators,node.data),[])
	else:
		print 'How to deal with',node.__class__.__name__,'?'
		return 0

def HAL(g):
	# Selectable, Marked, Plus, Star, Optional, Epsilon, Empty, Any, Choice, Sequence
	#mu1 = 10
	mu1 = len(allOperators(g))
	mu2 = VAR(g) + TERM(g) + VAL(g) + LAB(g)
	eta1 = opr(g)
	eta2 = opd(g)
	hal = (mu1*eta2*(eta1+eta2)*math.log(mu1+mu2,2)) / (2*mu2)
	return int(round(hal))

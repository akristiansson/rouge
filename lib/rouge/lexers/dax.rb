# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class DAX < RegexLexer
      title "DAX"
      desc "Data Analysis Expressions (DAX)"
      tag 'dax'
      filenames '*.dax'
      mimetypes 'text/x-dax'

      def self.keywords
        # source: https://docs.microsoft.com/en-us/dax/dax-queries
        @keywords ||= Set.new(%w(
            DEFINE MEASURE EVALUATE ORDER BY START AT ASC DESC RETURN
        ))
      end

      def self.names_function
        @names_function ||= Set.new %w(
            CALENDAR CALENDARAUTO DATE DATEDIFF DATEVALUE DAY EDATE EOMONTH HOUR 
            MINUTE MONTH NOW QUARTER SECOND TIME TIMEVALUE TODAY WEEKDAY WEEKNUM 
            YEAR YEARFRAC CLOSINGBALANCEMONTH CLOSINGBALANCEQUARTER CLOSINGBALANCEYEAR 
            DATEADD DATESBETWEEN DATESINPERIOD DATESMTD DATESQTD DATESYTD ENDOFMONTH 
            ENDOFQUARTER ENDOFYEAR FIRSTDATE FIRSTNONBLANK LASTDATE LASTNONBLANK 
            NEXTDAY NEXTMONTH NEXTQUARTER NEXTYEAR OPENINGBALANCEMONTH OPENINGBALANCEQUARTER 
            OPENINGBALANCEYEAR PARALLELPERIOD PREVIOUSDAY PREVIOUSMONTH PREVIOUSQUARTER 
            PREVIOUSYEAR SAMEPERIODLASTYEAR STARTOFMONTH STARTOFQUARTER STARTOFYEAR 
            TOTALMTD TOTALQTD TOTALYTD ADDMISSINGITEMS ALL ALLCROSSFILTERED ALLEXCEPT 
            ALLNOBLANKROW ALLSELECTED CALCULATE CALCULATETABLE CROSSFILTER DISTINCT 
            EARLIER EARLIEST FILTER FILTERS HASONEFILTER HASONEVALUE ISCROSSFILTERED 
            ISFILTERED KEEPFILTERS RELATED RELATEDTABLE REMOVEFILTERS SELECTEDVALUE 
            SUBSTITUTEWITHINDEX USERELATIONSHIP VALUES CONTAINS CUSTOMDATA ISBLANK 
            ISERROR ISEVEN ISINSCOPE ISLOGICAL ISNONTEXT ISNUMBER ISONORAFTER ISTEXT 
            LOOKUPVALUE USERNAME AND FALSE IF IFERROR NOT OR SWITCH TRUE ABS ACOS 
            ACOSH ASIN ASINH ATAN ATANH CEILING COMBIN COMBINA COS COSH CURRENCY DEGREES 
            DIVIDE EVEN EXP FACT FLOOR GCD INT ISO.CEILING LCM LN LOG LOG10 MROUND ODD PI 
            POWER PRODUCT PRODUCTX QUOTIENT RADIANS RAND RANDBETWEEN ROUND ROUNDDOWN ROUNDUP 
            SIGN SQRT SUM SUMX TRUNC CONVERT DATATABLE ERROR EXCEPT GENERATESERIES GROUPBY 
            INTERSECT ISEMPTY ISSELECTEDSMEASURE NATURALINNERJOIN NATURALLEFTOUTERJOIN 
            SELECTEDSMEASURE SELECTEDSMEASUREFORMATSTRING SELECTEDSMEASURENAME 
            SUMMARIZECOLUMNS TREATAS UNION PATH PATHCONTAINS PATHITEM PATHITEMREVERSE 
            PATHLENGTH ADDCOLUMNS APPROXIMATEDISTINCTCOUNT AVERAGE AVERAGEA AVERAGEX 
            BETA.DIST BETA.INV CHISQ.INV CHISQ.INV.RT CONFIDENCE.NORM CONFIDENCE.T COUNT 
            COUNTA COUNTAX COUNTBLANK COUNTROWS COUNTX CROSSJOIN  DISTINCTCOUNT 
            DISTINCTCOUNTNOBLANK EXPON.DIST GENERATE  GENERATEALL GEOMEAN GEOMEANX MAX MAXA 
            MAXX MEDIAN MEDIANX MIN MINA MINX NORM.DIST NORM.INV NORM.S.DIST NORM.S.INV 
            PERCENTILE.EXC PERCENTILE.INC PERCENTILEX.EXC PERCENTILEX.INC POISSON.DIST 
            RANK.EQ  RANKX ROW SAMPLE SELECTCOLUMNS SIN SINH STDEV.P STDEV.S STDEVX.P 
            STDEVX.S SQRTPI SUMMARIZE T.DIST T.DIST.2T T.DIST.RT T.INV T.INV.2t TAN TANH 
            TOPN VAR.P VAR.S VARX.P VARX.S XIRR XNPV BLANK CODE CONCATENATE CONCATENATEX 
            CONTAINSSTRING CONTAINSSTRINGEXACT EXACT FIND FIXED FORMAT LEFT LEN LOWER MID 
            REPLACE REPT RIGHT SEARCH SUBSTITUTE TRIM UNICHAR UPPER VALUE CURRENTGROUP
        )
      end

      state :root do
        rule %r/\s+/m, Text::Whitespace
        rule %r/\/\/.*/, Comment::Single
        rule %r(/\*), Comment::Multiline, :multiline_comments
        
        rule %r/[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)/, Num::Float
        rule %r/-?\d+\.\d+/, Num::Float
        rule %r/-?\d+/, Num::Integer
        
        

        # add Name::Variable for @param in xmla queries

        # Table names denoted with a single tick
        rule %r/'/, Name::Class, :single_string
        # Column names or metrics
        rule %r/\[/, Name::Attribute, :bracket
     
        # A double-quoted string refers to a database object in our default SQL
        # dialect, which is apropriate for e.g. MS SQL and PostgreSQL.
        rule %r/"/, Literal::String::Double, :double_string

        # functions, matching against function names followed by a opening bracket
        rule %r/[\w\.]+(?=(\s+)?\()/ do |m|
         if self.class.names_function.include? m[0].upcase
            token Name::Function
         end
        end

        
        rule %r/VAR/, Keyword::Declaration, :assignment
        
        rule %r/^(?!=).+?[^:\s]?(?=(\s+)?:?=)/, Name # Measure or table names (measure names are very relaxed)
        
        rule %r/\w[\w\d\.]*/ do |m|
          if self.class.keywords.include? m[0].upcase
            token Keyword
          else
            token Name
          end
        end
        
        rule %r/IN/, Operator::Word
        rule %r(:=|\|\||&&|==|<=|>=|<>|[\+\-\*\/\^=<>&]), Operator
        rule %r/[;:(){}\[\],.]/, Punctuation

        rule %r/@\w+/, Name::Variable::Instance
      end

      state :multiline_comments do
        rule %r(/[*]), Comment::Multiline, :multiline_comments
        rule %r([*]/), Comment::Multiline, :pop!
        rule %r([^/*]+), Comment::Multiline
        rule %r([/*]), Comment::Multiline
      end

      state :assignment do
        rule %r/\s+/m, Text::Whitespace
        rule %r/VAR/, Keyword::Declaration
        rule %r/\A(?![^a-zA-Z])\w+(?=(\s+)?=)/, Name::Variable, :pop! # variable names can contain but not start with numbers, they cannot contain non-ascii characters
        rule %r/\A.*\S(?=(\s+)?=)/, Error, :pop!
      end

      state :single_string do
        rule %r/\\./, Str::Escape
        rule %r/''/, Str::Escape
        rule %r/'/, Name::Class, :pop!
        rule %r/[^\\']+/, Name::Class
      end

      state :bracket do
        rule %r/\\./, Str::Escape
        rule %r/\]\]/, Str::Escape
        rule %r/\]/, Name::Attribute, :pop!
        rule %r/[^\\\]]+/, Name::Attribute
      end

      state :double_string do
        rule %r/\\./, Str::Escape
        rule %r/""/, Str::Escape
        rule %r/"/, Literal::String::Double, :pop!
        rule %r/[^\\"]+/, Literal::String::Double
      end
    end
  end
end

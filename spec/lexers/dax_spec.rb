# -*- coding: utf-8 -*- #
# frozen_string_literal: true

describe Rouge::Lexers::DAX do
  
  let(:subject) { Rouge::Lexers::DAX.new }

  describe 'guessing' do
    include Support::Guessing

    it 'guesses by filename' do
      assert_guess :filename => 'foo.dax'
    end

    it 'guesses by mimetype' do
      assert_guess :mimetype => 'text/x-dax'
    end
  end # guessing

  describe 'lexing' do
    include Support::Lexing
    
    describe 'comments' do
      it 'recognises one line comments' do
        assert_tokens_equal '// comment', ['Comment.Single', '// comment']
      end
      it 'recognises multiline comments' do
        assert_tokens_equal '/*\n RETURN SUM(1.23)\n*/', ['Comment.Multiline', '/*\n RETURN SUM(1.23)\n*/']
      end
    end # comments

    describe 'assignments' do

      it 'recognises nested assignments' do
        assert_tokens_equal 'Metric=VAR x=1 RETURN x+1.2',
            ['Name', 'Metric'],
            ['Operator', '='],
            ['Keyword.Declaration', 'VAR'],
            ['Text.Whitespace', ' '],
            ['Name.Variable', 'x'],
            ['Operator', '='],
            ['Literal.Number.Integer', '1'],
            ['Text.Whitespace', ' '],
            ['Keyword', 'RETURN'],
            ['Text.Whitespace', ' '],
            ['Name', 'x'],
            ['Operator', '+'],
            ['Literal.Number.Float', '1.2']
      end

      it 'recognises excel style assigments' do
        assert_tokens_equal 'Metric:=SUM(\'Table\'[Column])',
            ['Name', 'Metric'],
            ['Operator', ':='],
            ['Name.Function', 'SUM'],
            ['Punctuation', '('],
            ['Name.Class', '\'Table\''],
            ['Name.Attribute', '[Column]'],
            ['Punctuation', ')']
      end

      it 'recognises assignments on a new line' do
        assert_tokens_equal "VAR x=\nSUMX('Table',[Column]*2)",
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Name.Variable', 'x'],
          ['Operator', '='],
          ['Text.Whitespace', "\n"],
          ['Name.Function', 'SUMX'],
          ['Punctuation', '('],
          ['Name.Class', "'Table'"],
          ['Punctuation', ','],
          ['Name.Attribute', '[Column]'],
          ['Operator', '*'],
          ['Literal.Number.Integer', '2'],
          ['Punctuation', ')']
      end

      it 'doesnt allow funny variable names' do
        assert_tokens_equal "VAR two words=",
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Error', 'two words'],
          ['Operator', '=']
        
        assert_tokens_equal "VAR nönascii=".encode('utf-8'),
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Error', 'nönascii'],
          ['Operator', '=']

        assert_tokens_equal "VAR 1=",
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Error', '1'],
          ['Operator', '=']

        assert_tokens_equal "VAR $$$=",
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Error', '$$$'],
          ['Operator', '=']
      end

      it 'does allow variable names that does not start with a number' do
        assert_tokens_equal "VAR v1=",
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Name.Variable', 'v1'],
          ['Operator', '=']
      end

      it 'recognises nested assignments on a new line' do
        assert_tokens_equal "Metric=\nVAR x=1",
          ['Name', 'Metric'],
          ['Operator', '='],
          ['Text.Whitespace', "\n"],
          ['Keyword.Declaration', 'VAR'],
          ['Text.Whitespace', ' '],
          ['Name.Variable', 'x'],
          ['Operator', '='],
          ['Literal.Number.Integer', '1']
      end
    end # assignments

    describe 'numerics' do
      it 'distinguishes Float from Integer' do
        assert_tokens_equal "2.3 + 5",
          ['Literal.Number.Float', '2.3'],
          ['Text.Whitespace', ' '],
          ['Operator', '+'],
          ['Text.Whitespace', ' '],
          ['Literal.Number.Integer', '5']
      end

      it 'identifies Floats with exponent correctly' do
        assert_tokens_equal "12.3e4",
          ['Literal.Number.Float', '12.3e4']
        assert_tokens_equal "5.67e-9",
          ['Literal.Number.Float', '5.67e-9']
        assert_tokens_equal "20.4e+8",
          ['Literal.Number.Float', '20.4e+8']
      end
    end

  end # lexing
end # lexer

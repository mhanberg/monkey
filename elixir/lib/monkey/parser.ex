defmodule Monkey.Parser do
  alias Monkey.Ast
  alias Monkey.Lexer
  alias Monkey.Token
  alias Monkey.Parser

  for {k, v} <- Token.tokens() do
    Module.put_attribute(__MODULE__, :"token_#{k}", v)
  end

  @lowest 1
  @equals 2
  @lessgreater 3
  @sum 4
  @product 5
  @prefix 6
  @call 7

  @precedences %{
    @token_eq => @equals,
    @token_not_eq => @equals,
    @token_lt => @lessgreater,
    @token_gt => @lessgreater,
    @token_plus => @sum,
    @token_minus => @sum,
    @token_slash => @product,
    @token_asterisk => @product,
    @token_lparen => @call
  }

  @type prefix_parse_function :: (t() -> map())
  @type infix_parse_function :: (t(), map() -> map())

  @type prefix_parse_function_map :: %{Token.token_type() => prefix_parse_function()}
  @type infix_parse_function_map :: %{Token.token_type() => infix_parse_function()}

  defstruct [
    :lexer,
    :current_token,
    :peek_token,
    errors: [],
    prefix_parse_functions: %{},
    infix_parse_functions: %{}
  ]

  @type t :: %__MODULE__{
          lexer: Lexer.t(),
          current_token: Token.t(),
          peek_token: Token.t(),
          errors: [String.t()],
          prefix_parse_functions: prefix_parse_function_map(),
          infix_parse_functions: infix_parse_function_map()
        }

  def new(%Lexer{} = lexer) do
    %__MODULE__{
      lexer: lexer,
      prefix_parse_functions: %{
        @token_ident => &parse_identifier/1,
        @token_int => &parse_integer_literal/1,
        @token_bang => &parse_prefix_expression/1,
        @token_minus => &parse_prefix_expression/1,
        @token_true => &parse_boolean/1,
        @token_false => &parse_boolean/1,
        @token_lparen => &parse_grouped_expression/1,
        @token_if => &parse_if_expression/1,
        @token_function => &parse_function_literal/1
      },
      infix_parse_functions: %{
        @token_eq => &parse_infix_expression/2,
        @token_not_eq => &parse_infix_expression/2,
        @token_lt => &parse_infix_expression/2,
        @token_gt => &parse_infix_expression/2,
        @token_plus => &parse_infix_expression/2,
        @token_minus => &parse_infix_expression/2,
        @token_slash => &parse_infix_expression/2,
        @token_asterisk => &parse_infix_expression/2,
        @token_lparen => &parse_call_expression/2
      }
    }
    |> next_token()
    |> next_token()
  end

  defp next_token(%__MODULE__{} = parser) do
    {lexer, token} = Lexer.next_token(parser.lexer)

    %{
      parser
      | lexer: lexer,
        current_token: parser.peek_token,
        peek_token: token
    }
  end

  def parse_program(%__MODULE__{} = parser) do
    program = %Ast.Program{}

    {parser, program} = parse_program_statement(parser, program)

    parser = next_token(parser)

    {%{parser | errors: Enum.reverse(parser.errors)},
     %{
       program
       | statements: Enum.reverse(program.statements)
     }}
  end

  defp parse_program_statement(
         %Parser{current_token: %Token{type: type}} = parser,
         %Ast.Program{} = program
       )
       when type != @token_eof do
    {parser, statement} = parse_statement(parser)

    program =
      if statement != nil do
        %Ast.Program{program | statements: [statement | program.statements]}
      else
        program
      end

    parser = next_token(parser)

    parse_program_statement(parser, program)
  end

  defp parse_program_statement(parser, program) do
    {parser, program}
  end

  defp parse_statement(%Parser{} = parser) do
    case parser.current_token.type do
      @token_let ->
        parse_let_statement(parser)

      @token_return ->
        parse_return_statement(parser)

      _ ->
        parse_expression_statement(parser)
    end
  end

  defp parse_let_statement(%Parser{} = parser) do
    statement = %Ast.LetStatement{token: parser.current_token}

    case expect_peek(parser, @token_ident) do
      {:ok, parser} ->
        statement = %{
          statement
          | name: %Ast.Identifier{
              token: parser.current_token,
              value: parser.current_token.literal
            }
        }

        case expect_peek(parser, @token_assign) do
          {:ok, parser} ->
            parser = next_token(parser)

            {parser, value} = parse_expression(parser, @lowest)
            parser = eat_until_semicolon(parser)

            {parser, %{statement | value: value}}

          {:error, parser} ->
            {parser, nil}
        end

      {:error, parser} ->
        {parser, nil}
    end
  end

  defp parse_return_statement(%__MODULE__{} = parser) do
    statement = %Ast.ReturnStatement{token: parser.current_token}

    parser = next_token(parser)

    {parser, return_value} = parse_expression(parser, @lowest)

    parser = eat_until_semicolon(parser)

    {parser, %{statement | return_value: return_value}}
  end

  defp parse_expression_statement(%__MODULE__{} = parser) do
    {parser, expression} = parse_expression(parser, @lowest)

    statement = %Ast.ExpressionStatement{
      token: parser.current_token,
      expression: expression
    }

    parser =
      if is_peek_token?(parser, @token_semicolon) do
        next_token(parser)
      else
        parser
      end

    {parser, statement}
  end

  defp parse_expression(%__MODULE__{} = parser, precedence) do
    prefix = parser.prefix_parse_functions[parser.current_token.type]

    if prefix == nil do
      parser =
        put_parser_error(
          parser,
          "no prefix parse function for #{parser.current_token.type} found"
        )

      {parser, nil}
    else
      {parser, left_expression} = prefix.(parser)

      while(
        {parser, left_expression},
        fn {parser, _} ->
          !is_peek_token?(parser, @token_semicolon) && precedence < peek_precedence(parser)
        end,
        fn {parser, left_expression} ->
          infix = parser.infix_parse_functions[parser.peek_token.type]

          if infix == nil do
            {parser, left_expression}
          else
            parser = next_token(parser)

            infix.(parser, left_expression)
          end
        end
      )
    end
  end

  defp eat_until_semicolon(%Parser{current_token: %Token{type: current_token}} = parser)
       when current_token != @token_semicolon do
    parser
    |> next_token()
    |> eat_until_semicolon()
  end

  defp eat_until_semicolon(parser) do
    parser
  end

  defp is_peek_token?(%Parser{peek_token: peek_token}, token_type) do
    peek_token.type == token_type
  end

  @spec expect_peek(t(), Token.token_type()) :: {:ok, t()} | {:error, t()}
  defp expect_peek(parser, token_type) do
    if is_peek_token?(parser, token_type) do
      parser = next_token(parser)
      {:ok, parser}
    else
      parser = peek_error(parser, token_type)
      {:error, parser}
    end
  end

  defp parse_identifier(%__MODULE__{} = parser) do
    {parser, %Ast.Identifier{token: parser.current_token, value: parser.current_token.literal}}
  end

  defp parse_integer_literal(%__MODULE__{} = parser) do
    ast = %Ast.IntegerLiteral{token: parser.current_token}

    case Integer.parse(parser.current_token.literal) do
      :error ->
        {put_parser_error(parser, "could not parse #{parser.current_token.literal} as integer"),
         nil}

      {value, _} ->
        {parser, %{ast | value: value}}
    end
  end

  defp parse_prefix_expression(%__MODULE__{} = parser) do
    ast = %Ast.PrefixExpression{
      token: parser.current_token,
      operator: parser.current_token.literal
    }

    parser = next_token(parser)

    {parser, right} = parse_expression(parser, @prefix)

    {parser, %{ast | right: right}}
  end

  defp parse_infix_expression(%__MODULE__{} = parser, expression) do
    ast = %Ast.InfixExpression{
      token: parser.current_token,
      operator: parser.current_token.literal,
      left: expression
    }

    precedence = current_precedence(parser)
    parser = next_token(parser)

    {parser, right} = parse_expression(parser, precedence)

    {parser, %{ast | right: right}}
  end

  defp parse_boolean(%__MODULE__{} = parser) do
    {parser,
     %Ast.Boolean{token: parser.current_token, value: parser.current_token.type == @token_true}}
  end

  defp parse_grouped_expression(%__MODULE__{} = parser) do
    parser = next_token(parser)

    {parser, expression} = parse_expression(parser, @lowest)

    case expect_peek(parser, @token_rparen) do
      {:ok, parser} ->
        {parser, expression}

      {:error, parser} ->
        {parser, nil}
    end
  end

  defp parse_if_expression(%__MODULE__{} = parser) do
    expression = %Ast.IfExpression{token: parser.current_token}

    case expect_peek(parser, @token_lparen) do
      {:error, parser} ->
        {parser, nil}

      {:ok, parser} ->
        parser = next_token(parser)

        {parser, condition} = parse_expression(parser, @lowest)

        with {:ok, parser} <- expect_peek(parser, @token_rparen),
             {:ok, parser} <- expect_peek(parser, @token_lbrace) do
          {parser, consequence} = parse_block_statement(parser)

          {parser, alternative} =
            if is_peek_token?(parser, @token_else) do
              parser = next_token(parser)

              case expect_peek(parser, @token_lbrace) do
                {:ok, parser} ->
                  parse_block_statement(parser)

                {:error, parser} ->
                  {parser, nil}
              end
            else
              {parser, nil}
            end

          {parser,
           %{
             expression
             | condition: condition,
               consequence: consequence,
               alternative: alternative
           }}
        else
          {:error, parser} ->
            {parser, nil}
        end
    end
  end

  defp parse_block_statement(%__MODULE__{} = parser) do
    block = %Ast.BlockStatement{token: parser.current_token, statements: []}

    parser = next_token(parser)

    while(
      {parser, block},
      fn {parser, _} ->
        parser.current_token.type != @token_rbrace && parser.current_token.type != @token_eof
      end,
      fn {parser, block} ->
        {parser, statement} = parse_statement(parser)

        block =
          if statement do
            %{block | statements: block.statements ++ [statement]}
          else
            block
          end

        {next_token(parser), block}
      end
    )
  end

  defp parse_function_literal(%__MODULE__{} = parser) do
    function = %Ast.FunctionLiteral{token: parser.current_token}

    case expect_peek(parser, @token_lparen) do
      {:ok, parser} ->
        {parser, parameters} = parse_function_parameters(parser)

        case expect_peek(parser, @token_lbrace) do
          {:ok, parser} ->
            {parser, body} = parse_block_statement(parser)

            {parser, %{function | parameters: parameters, body: body}}

          {:error, parser} ->
            {parser, nil}
        end

      {:error, parser} ->
        {parser, nil}
    end
  end

  defp parse_function_parameters(%__MODULE__{} = parser) do
    identifiers = []

    if is_peek_token?(parser, @token_rparen) do
      parser = next_token(parser)

      {parser, identifiers}
    else
      parser = next_token(parser)

      ident = %Ast.Identifier{token: parser.current_token, value: parser.current_token.literal}
      identifiers = identifiers ++ [ident]

      {parser, identifiers} =
        while(
          {parser, identifiers},
          fn {parser, _} -> is_peek_token?(parser, @token_comma) end,
          fn {parser, identifiers} ->
            parser = parser |> next_token() |> next_token()

            ident = %Ast.Identifier{
              token: parser.current_token,
              value: parser.current_token.literal
            }

            {parser, identifiers ++ [ident]}
          end
        )

      case expect_peek(parser, @token_rparen) do
        {:ok, parser} ->
          {parser, identifiers}

        {:error, parser} ->
          {parser, nil}
      end
    end
  end

  def parse_call_expression(%__MODULE__{} = parser, expression) do
    expression = %Ast.CallExpression{token: parser.current_token, function: expression}

    {parser, call_args} = parse_call_arguments(parser)

    {parser, %{expression | arguments: call_args}}
  end

  defp parse_call_arguments(%__MODULE__{} = parser) do
    args = []

    if is_peek_token?(parser, @token_rparen) do
      parser = next_token(parser)

      {parser, args}
    else
      parser = next_token(parser)
      {parser, expression} = parse_expression(parser, @lowest)
      args = args ++ [expression]

      {parser, args} =
        while(
          {parser, args},
          fn {parser, _} -> is_peek_token?(parser, @token_comma) end,
          fn {parser, args} ->
            parser = parser |> next_token() |> next_token()

            {parser, expression} = parse_expression(parser, @lowest)
            {parser, args ++ [expression]}
          end
        )

      case expect_peek(parser, @token_rparen) do
        {:ok, parser} ->
          {parser, args}

        {:error, parser} ->
          {parser, nil}
      end
    end
  end

  def peek_error(%__MODULE__{} = parser, token_type) do
    put_parser_error(
      parser,
      "expected next token to be #{token_type}, got #{parser.peek_token.type} instead"
    )
  end

  def peek_precedence(%__MODULE__{} = parser) do
    Map.get(@precedences, parser.peek_token.type, @lowest)
  end

  def current_precedence(%__MODULE__{} = parser) do
    Map.get(@precedences, parser.current_token.type, @lowest)
  end

  defp put_parser_error(parser, message) do
    %{parser | errors: [message | parser.errors]}
  end

  defp while(acc, predicate, body) do
    if predicate.(acc) do
      acc = body.(acc)

      while(acc, predicate, body)
    else
      acc
    end
  end
end

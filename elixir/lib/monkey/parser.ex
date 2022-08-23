defmodule Monkey.Parser do
  alias Monkey.Ast
  alias Monkey.Lexer
  alias Monkey.Token
  alias Monkey.Parser

  for {k, v} <- Token.tokens() do
    Module.put_attribute(__MODULE__, :"token_#{k}", v)
  end

  defstruct [:lexer, :current_token, :peek_token, errors: []]

  def new(%Lexer{} = lexer) do
    %__MODULE__{lexer: lexer} |> next_token() |> next_token()
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

    {parser, %{program | statements: Enum.reverse(program.statements)}}
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
        {parser, nil}
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
            parser = eat_until_semicolon(parser)

            {parser, statement}

          {:error, parser} ->
            {parser, nil}
        end

      {:error, parser} ->
        {parser, nil}
    end
  end

  defp parse_return_statement(%__MODULE__{} = parser) do
    statement = %Ast.ReturnStatement{token: parser.current_token}

    parser =
      parser
      |> next_token()
      |> eat_until_semicolon()

    {parser, statement}
  end

  defp eat_until_semicolon(%Parser{current_token: current_token} = parser)
       when current_token != @token_semicolon do
    next_token(parser)
  end

  defp eat_until_semicolon(parser) do
    parser
  end

  defp is_peek_token?(%Parser{peek_token: peek_token}, token_type) do
    peek_token.type == token_type
  end

  defp expect_peek(parser, token_type) do
    if is_peek_token?(parser, token_type) do
      parser = next_token(parser)
      {:ok, parser}
    else
      parser = peek_error(parser, token_type)
      {:error, parser}
    end
  end

  def peek_error(%__MODULE__{} = parser, token_type) do
    message = "expected next token to be #{token_type}, got #{parser.peek_token.type} instead"

    %{parser | errors: [message | parser.errors]}
  end
end

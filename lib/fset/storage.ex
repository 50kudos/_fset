defmodule Fset.Storage do
  @moduledoc """
  The Storage context.
  """

  import Ecto.Query, warn: false
  alias Fset.Repo

  alias Fset.Storage.OauthToken

  @doc """
  Returns the list of oauth_tokens.

  ## Examples

      iex> list_oauth_tokens()
      [%OauthToken{}, ...]

  """
  def list_oauth_tokens do
    Repo.all(OauthToken)
  end

  @doc """
  Gets a single oauth_token.

  Raises `Ecto.NoResultsError` if the Oauth token does not exist.

  ## Examples

      iex> get_oauth_token!(123)
      %OauthToken{}

      iex> get_oauth_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_oauth_token!(id), do: Repo.get!(OauthToken, id)

  @doc """
  Creates a oauth_token.

  ## Examples

      iex> create_oauth_token(%{field: value})
      {:ok, %OauthToken{}}

      iex> create_oauth_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_oauth_token(attrs \\ %{}) do
    %OauthToken{}
    |> OauthToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a oauth_token.

  ## Examples

      iex> update_oauth_token(oauth_token, %{field: new_value})
      {:ok, %OauthToken{}}

      iex> update_oauth_token(oauth_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_oauth_token(%OauthToken{} = oauth_token, attrs) do
    oauth_token
    |> OauthToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a oauth_token.

  ## Examples

      iex> delete_oauth_token(oauth_token)
      {:ok, %OauthToken{}}

      iex> delete_oauth_token(oauth_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_oauth_token(%OauthToken{} = oauth_token) do
    Repo.delete(oauth_token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking oauth_token changes.

  ## Examples

      iex> change_oauth_token(oauth_token)
      %Ecto.Changeset{data: %OauthToken{}}

  """
  def change_oauth_token(%OauthToken{} = oauth_token, attrs \\ %{}) do
    OauthToken.changeset(oauth_token, attrs)
  end
end

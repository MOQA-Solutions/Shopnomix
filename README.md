# Ecto.Changeset to Javin Change

We store data in Postgres using a few custom types and a couple of custom functions.

The types are:

- pgjavin_atom
- pgjavin_objectid
- pgjavin_operation
- pgjavin_compact_change

The custom functions are:

- pgjavin_commit_changes4
- pgjavin_next_server_pk

This project is about taking an `Ecto.Changeset` and `Ecto.Multi` and converting them to a `Javin Change` or an array of `Javin Change`.

A `Javin Change` is custom Postgres type defined as follows:

## Types

### pgjavin_atom

This is a key value pair. The key is a string that presents a column name. The value is a `packed value` that represents the data (in a tagged format).

### pgjavin_objectid

This is a basic structure that represents the tablename (called classname) and primary key (big int).

### pgjavin_operation

This is a simple string enum with only 3 options (insert, update, delete).

### pgjavin_compact_change

This is structure that contains 3 things: the object id (tablename + pkey), the operation (insert, update, delete) and an array of atoms (key value pairs).

So a single "change" can only describe 1 operation happening to exactly 1 row in 1 table.

## Functions

### pgjavin_next_server_pk

This return the next primary key for a given customer (customer_id) and table (classname).
All primary keys are big integer with gaps of 1000, so the first row in a table would be 1000, the second row would be 2000 etc...
This allows us to have 998 independant client nodes (0 is the server and 999 is reserved for repairs).

### pgjavin_commit_changes4

This function is the gatekeeper of any insert, update, delete to the database. Any application that connects has no permission to directly insert, update or delete. Applications must use the commit_changes function. This guarantees the change log is always valid.

The arguments are (in order):

- customer_id (big int)
- array of pgjavin_compact_change
- the postgres schema name (i.e. public)
- the schema version (big int)
- the application name (i.e. Daylite for mac)
- the client identifier (a uuid representing the device)
- the ip address of sender
- the user agent (i.e. apple urlsession)
- an idempotency token to guard against replays

On success, it returns a boolean, or it can raise (postgres) exceptions on failure including the inability to obtain a lock for writing.
In the event of a lock failure, you must retry (ruby code shows this).

## SQL

The following is are the sql type definitions.

```sql

CREATE TYPE pgjavin.pgjavin_atom AS
(key character varying,
value bytea);

CREATE TYPE pgjavin_operation AS ENUM
   ('insert',
    'update',
    'delete');

CREATE TYPE pgjavin_objectid AS
   (class character varying,
    id bigint);


CREATE TYPE pgjavin_compact_change AS (objectid pgjavin_objectid,
			                           operation pgjavin_operation,
                                       atoms pgjavin_atom[]);


```

The following are the sql function definitions.

```sql

CREATE OR REPLACE FUNCTION pgjavin.pgjavin_next_server_pk(i_customer BIGINT, i_schema_identifier text, i_class_name text) RETURNS BIGINT



BEGIN
    RETURN pgjavin.pgjavin_commit_changes4(i_customer_id,
                                           i_changes,
                                           i_schema_name,
                                           i_schema_version,
                                           i_application_name,
                                           i_client_identifier,
                                           i_ip_address,
                                           i_user_agent,
					   NULL);
END
$$ LANGUAGE plpgsql VOLATILE NOT LEAKPROOF SECURITY DEFINER;

CREATE OR REPLACE FUNCTION pgjavin.pgjavin_commit_changes4(
    i_customer_id bigint,
    i_changes pgjavin.pgjavin_compact_change[],
    i_schema_name text,
    i_schema_version bigint,
    i_application_name text,
    i_client_identifier text,
    i_ip_address text,
    i_user_agent jsonb,
    i_idempotency_token text)
RETURNS boolean AS
$


```

## Python

The following is the python code that represents the types.

```python

class Operation(Enum):
    """
    For pgjavin_operation.
    """
    insert = 1 << 1
    update = 1 << 2
    delete = 1 << 3

    @staticmethod
    def from_string(string: str) -> 'Operation':
        if string == 'insert':
            return Operation.insert
        if string == 'update':
            return Operation.update
        if string == 'delete':
            return Operation.delete


class ObjectID(typing.NamedTuple):
    """
    For pgjavin_objectid.
    """
    class_: str
    id_: int


class ChangeID(typing.NamedTuple):
    """
    For pgjavin_changeid.
    """
    sync_id: int
    change_id: int


class Atom(typing.NamedTuple):
    """
    For pgjavin_atom.
    """
    key: str
    value: bytes


class CompactChange:
    """
    Python representation of the pgjavin_compact_change
    PostgreSQL datatype
    """

    object_id: ObjectID
    operation: str
    atoms: List[Atom]

    def __init__(self, object_id: ObjectID, operation: str, atoms: List[Atom]):
        self.object_id = object_id
        self.operation = operation
        self.atoms = atoms

    def __eq__(self, other: 'CompactChange'):
        return self.object_id == other.object_id and \
               self.operation == other.operation and \
               self.atoms == other.atoms

    def __len__(self):
        return 3

    def __getitem__(self, item):
        if item == 0:
            return self.object_id
        if item == 1:
            return self.operation
        if item == 2:
            return self.atoms
        return None

    @property
    def bind_representation(self):
        return (self.object_id,
                self.operation,
                self.atoms)



```

The following is an example of how the commit function is called from Python.

```python

SQL_QUERIES = {
    "commit_changes": "SELECT pgjavin.pgjavin_commit_changes4($1, $2, $3, $4, $5, $6, $7, $8, $9)",
}




    async def commit_changes(self,
                             customer_id: int,
                             changes: List[CompactChange],
                             application_name: str,
                             client_identifier: str,
                             ip_address: str,
                             user_agent=None,
                             idempotency_token: Optional[str] = None) -> bool:
        """
        This function writes changes to the shard & data table.  Used for
        unit tests.
        """
        if user_agent is None:
            user_agent = {}
        query = SQL_QUERIES["commit_changes"]
        try:
            return await self.fetchval(
                query,
                customer_id,
                [change.bind_representation for change in changes],
                self._schema,
                self._schema_version,
                application_name,
                client_identifier,
                ip_address,
                json.dumps(user_agent),
                idempotency_token
            )
        except UniqueViolationError as error:
            logger.warning("Unique violation error: %s", error)
            raise error


```

The following is Python that shows the exception handling.

```python

            try:
                device_id = request.headers.get('mcdevice')
                if device_id:
                    device_id = base64.b64decode(device_id).decode('utf-8')
                else:
                    device_id = 'unknown'
                logger.info('Attempting to commit changes',
                            extra=log_context)
                busy = not await data_store.commit_changes(request['customer_id'],
                                                           compact_changes,
                                                           request.headers.get('mcapp', 'unknown'),
                                                           device_id,
                                                           request.headers.get('x-forwarded-for', '::'),
                                                           user_agent=_extract_commit_user_agent(request),
                                                           idempotency_token=idempotency_token)
                if busy:
                    error_uuid = str(uuid4())
                    log_context['error_uuid'] = error_uuid
                    logger.warning("Datastore is already locked for customer",
                                   extra=log_context)
                    return protobuf_response(DataStoreBusy(error_uuid=error_uuid), 423)
            except asyncpg.NotNullViolationError as error:
                parsed_error = parse_non_null_column(error)
                log_context.update(parsed_error)
                error_uuid = str(uuid4())
                log_context['error_uuid'] = error_uuid
                logger.warning("Failed to commit changes due to a not null violation",
                               extra=log_context)
                return protobuf_response(BadClientData(type=BadClientData.Type.CONSTRAINT_VIOLATION,
                                                       error_uuid=error_uuid,
                                                       offending_change=message.changes[parsed_error['index']]), 400)
            except asyncpg.UndefinedColumnError as error:
                parsed_error = parse_undefined_column(error)
                log_context.update(parsed_error)
                logger.warning("Failed to commit changes due to an undefined column violation",
                               extra=log_context)
                return protobuf_response(BadClientData(type=BadClientData.Type.UNKNOWN_ATTRIBUTE,
                                                       offending_change=message.changes[parsed_error['index']]), 400)
            except asyncpg.UniqueViolationError as error:
                parsed_error = parse_daylite_pk_violation(error)
                log_context.update(parsed_error)
                logger.warning("Failed to commit changes due to a pkey violation",
                               extra=log_context)
                return protobuf_response(BadClientData(type=BadClientData.Type.PK_VIOLATION,
                                                       offending_change=message.changes[parsed_error['index']]), 400)
            except asyncpg.DatatypeMismatchError as error:
                log_context["error"] = str(error)
                logger.warning("Failed to commit changes due to a datatype mismatch",
                               extra=log_context)
                return protobuf_response(BadClientData(type=BadClientData.Type.TYPE_ERROR), 400)

            except Exception as error:
                log_context["error"] = str(error)
                logger.error("Failed to commit changes due to an error",
                             extra=log_context)
                raise HTTPInternalServerError

            last_id = await data_store.last_sync_id(request['customer_id'])
            logger.info("Successfully committed changes",
                        extra=log_context)


```

## Ruby

The following is Ruby code that shows getting the next primary key for a given table and customer_id.

```ruby

        NEXT_PK_SQL = <<~SQL
          SELECT pgjavin.pgjavin_next_server_pk($1::bigint, $2::text, $3::text)
        SQL

i        # @param relation [String] table name
        def next_rowid_for relation, customer_id
          schema_name = 'com.marketcircle.daylite'

          binds = [
            customer_id,
            schema_name,
            relation
          ]

          log_binds = [
            Relation::QueryAttribute.new('customer_id', customer_id, INT),
            Relation::QueryAttribute.new('schema_name', schema_name, STRING),
            Relation::QueryAttribute.new('class_name',  relation,    STRING)
          ]

          log(
            NEXT_PK_SQL,
            'PGJAVIN',
            log_binds,
            binds
          ) do
            result = @connection.exec_params(NEXT_PK_SQL, binds)
            rowid = result.getvalue(0, 0)
            result.clear
            rowid
          end
        end



```

The following is Ruby code that shows how to commit changes (using 1 less argument).
It shows retrying 3 times in the event of a lock contention.

```ruby

        # CREATE OR REPLACE FUNCTION pgjavin.pgjavin_commit_changes3(
        # i_customer_id bigint,
        # i_changes pgjavin.pgjavin_compact_change[],
        # i_schema_name text,
        # i_schema_version bigint,
        # i_application_name text,
        # i_client_identifier text,
        # i_ip_address text,
        # i_user_agent jsonb)
        # RETURNS boolean
        COMMIT_CHANGES_SQL = <<~SQL
          SELECT pgjavin.pgjavin_commit_changes3(
                 $1::bigint,
                 $2::pgjavin.pgjavin_compact_change[],
                 $3::text,
                 $4::bigint,
                 $5::text,
                 $6::text,
                 $7::text,
                 $8::jsonb
                 )
        SQL

        ##
        # @todo binary serialization of arguments, allowing us to
        #       use the prepared statement execution method
        #
        # Binds are formatted by Changes.to_binds
        #
        # @param changes [Changes]
        def commit_changes changes, retries = 3
          binds = changes.to_binds
          sql = "SELECT pgjavin.pgjavin_commit_changes3(#{binds.join(',')})"

          log(
            COMMIT_CHANGES_SQL,
            'PGJAVIN'
          ) do
            result = nil
            retries.times do |backoff_exponent|
              result = @connection.exec(sql)
              result.check
              if result.getvalue(0, 0)
                result.clear
                return true
              end
              sleep(2**backoff_exponent)
            end
            raise CustomerLockContention.new(result)
          end
        end



```

## Ecto Solution

We need our system to work nicely with the rest of the Phoenix, Ecto & Elixir systems.
From initial research, this should be fairly straightforward.

### Types

The data structures are pretty simple. I think we should use `[Ecto.type](https://hexdocs.pm/ecto/Ecto.Type.html)` unless there is a good reason not to.
An example implementation can be found [here](https://github.com/davydog187/ecto_range).

### Changeset

We should be able to transform a `Ecto.Changeset` into a `pgjavin.pgjavin_compact_change`, where each field value is encoded in a `packed value` and put into `pgjavin_atom` using the field name (column name) as the key.

The operation is easy to derive.

For the `pgjavin.objectid` we use the primary key and the tablename.

For `insert` operations, we need to get the next primary key for the table using a function call.

### Repo

We will obviously need a special `Repo` which supports multi-tenancy and a few other constraints such as soft-deletes, however that is not in the scope of this project. For this project we just need something that proves we can take a `Changeset`, transform it, then save it using `pgjavin.commit_changes4()`.

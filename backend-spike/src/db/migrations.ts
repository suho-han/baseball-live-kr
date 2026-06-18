import type { DatabaseSync } from 'node:sqlite'

interface Migration {
  version: number
  name: string
  sql: string
}

const migrations: Migration[] = [
  {
    version: 1,
    name: 'db_foundation',
    sql: `
      create table if not exists schema_migrations (
        version integer primary key,
        name text not null,
        applied_at text not null
      );

      create table if not exists raw_sources (
        id text primary key,
        source text not null,
        endpoint text not null,
        request_key text not null,
        fetched_at text not null,
        status_code integer,
        checksum text not null,
        body text not null
      );

      create unique index if not exists idx_raw_sources_checksum
        on raw_sources(source, endpoint, request_key, checksum);

      create index if not exists idx_raw_sources_lookup
        on raw_sources(source, endpoint, request_key, fetched_at desc);

      create table if not exists teams (
        id text primary key,
        short_name text not null,
        full_name text not null,
        normalized_name text not null,
        active_from integer,
        active_to integer,
        created_at text not null,
        updated_at text not null
      );

      create table if not exists games (
        game_id text primary key,
        season integer not null,
        date text not null,
        away_team_id text not null,
        home_team_id text not null,
        venue text,
        start_time text,
        status text not null,
        created_at text not null,
        updated_at text not null
      );

      create index if not exists idx_games_date
        on games(date);

      create table if not exists game_snapshots (
        id text primary key,
        game_id text not null,
        captured_at text not null,
        status text not null,
        inning_number integer,
        inning_half text,
        away_score integer,
        home_score integer,
        raw_source_id text,
        normalized_json text not null,
        foreign key (game_id) references games(game_id),
        foreign key (raw_source_id) references raw_sources(id)
      );

      create index if not exists idx_game_snapshots_game_time
        on game_snapshots(game_id, captured_at desc);
    `
  },
  {
    version: 2,
    name: 'team_season_records',
    sql: `
      create table if not exists team_season_records (
        season integer not null,
        date text not null,
        team_id text not null,
        team_name text not null,
        rank integer,
        games integer,
        wins integer,
        losses integer,
        draws integer,
        winning_percentage real,
        games_behind text,
        recent_10 text,
        streak text,
        home_record text,
        away_record text,
        runs_scored integer,
        runs_allowed integer,
        source text not null,
        raw_source_id text,
        created_at text not null,
        updated_at text not null,
        primary key (season, date, team_id),
        foreign key (team_id) references teams(id),
        foreign key (raw_source_id) references raw_sources(id)
      );

      create index if not exists idx_team_season_records_team_date
        on team_season_records(team_id, season, date desc);
    `
  },
  {
    version: 3,
    name: 'player_records',
    sql: `
      create table if not exists players (
        id text primary key,
        name text not null,
        normalized_name text not null,
        birth_date text,
        throws text,
        bats text,
        created_at text not null,
        updated_at text not null
      );

      create index if not exists idx_players_normalized_name
        on players(normalized_name);

      create table if not exists player_team_seasons (
        player_id text not null,
        team_id text not null,
        season integer not null,
        uniform_number text,
        position text,
        created_at text not null,
        updated_at text not null,
        primary key (player_id, team_id, season),
        foreign key (player_id) references players(id),
        foreign key (team_id) references teams(id)
      );

      create table if not exists player_batting_season_records (
        season integer not null,
        date text not null,
        player_id text not null,
        team_id text not null,
        rank integer,
        games integer,
        plate_appearances integer,
        at_bats integer,
        hits integer,
        doubles integer,
        triples integer,
        home_runs integer,
        total_bases integer,
        rbi integer,
        runs integer,
        walks integer,
        strikeouts integer,
        stolen_bases integer,
        caught_stealing integer,
        sacrifice_hits integer,
        sacrifice_flies integer,
        avg real,
        obp real,
        slg real,
        ops real,
        source text not null,
        raw_source_id text,
        created_at text not null,
        updated_at text not null,
        primary key (season, date, player_id, team_id),
        foreign key (player_id) references players(id),
        foreign key (team_id) references teams(id),
        foreign key (raw_source_id) references raw_sources(id)
      );

      create index if not exists idx_player_batting_latest
        on player_batting_season_records(player_id, season, date desc);

      create table if not exists player_pitching_season_records (
        season integer not null,
        date text not null,
        player_id text not null,
        team_id text not null,
        rank integer,
        games integer,
        games_started integer,
        complete_games integer,
        shutouts integer,
        wins integer,
        losses integer,
        saves integer,
        holds integer,
        winning_percentage real,
        plate_appearances integer,
        pitches integer,
        innings_pitched_outs integer,
        hits_allowed integer,
        doubles_allowed integer,
        triples_allowed integer,
        home_runs_allowed integer,
        walks integer,
        strikeouts integer,
        earned_runs integer,
        era real,
        whip real,
        source text not null,
        raw_source_id text,
        created_at text not null,
        updated_at text not null,
        primary key (season, date, player_id, team_id),
        foreign key (player_id) references players(id),
        foreign key (team_id) references teams(id),
        foreign key (raw_source_id) references raw_sources(id)
      );

      create index if not exists idx_player_pitching_latest
        on player_pitching_season_records(player_id, season, date desc);
    `
  }
]

export function runMigrations(db: DatabaseSync): void {
  db.exec(`
    create table if not exists schema_migrations (
      version integer primary key,
      name text not null,
      applied_at text not null
    );
  `)

  const hasMigration = db.prepare('select 1 from schema_migrations where version = ? limit 1')
  const insertMigration = db.prepare('insert into schema_migrations (version, name, applied_at) values (?, ?, ?)')

  db.exec('begin')
  try {
    for (const migration of migrations) {
      if (hasMigration.get(migration.version)) {
        continue
      }

      db.exec(migration.sql)
      insertMigration.run(migration.version, migration.name, new Date().toISOString())
    }

    db.exec('commit')
  } catch (error) {
    db.exec('rollback')
    throw error
  }
}

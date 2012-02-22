//
// Copyright (C) 2011 Eamon Millman
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.
//

#include <stdio.h>
#include <stdlib.h>
#include <new>
#include <iostream>
#include "Instrument.h"

#include "LoggerEvent_m.h"

Define_Module(Instrument);

void Instrument::initialize( int stage )
{
	if( stage == 0 )
	{
		
		enabled = par("enabled").boolValue();


		if( enabled )
		{
			// determine format
			compress = par("compress").longValue();
			switch( compress )
			{
			case 0:
			case 1:
			case 2:
				break;
			default:
				cRuntimeError("invalid compression: 0 - none, 1 - post tar.gz, 2 - bz2 at runtime");
			}
			readable = par("readable").boolValue();
			recordBytes = parseFormat( par("format") );

			if( recordBytes == 0 )
				cRuntimeError("no valid format found, must be > 0 bytes");

			maxBytes = par("maxBytes").longValue();
			if( maxBytes < recordBytes )
				maxBytes = recordBytes;
			
			maxRecords = maxBytes / recordBytes;
			
			bufferedBytes = 0;
			curRecord = 0;
			first = true;
			const char* config = simulation.getActiveEnvir()->getConfigEx()->getActiveConfigName();
			int run = simulation.getActiveEnvir()->getConfigEx()->getActiveRunNumber();

			for( unsigned int i = 0; i < format.size(); i++ )
			{
				char strbuffer[512];

				sprintf( strbuffer, "mkdir -p %s &> /dev/null", par("path").stringValue());
				system( strbuffer );

				if( compress == 2 )
				{
					sprintf( strbuffer, "%s/%s%d-%s-%d.log.bz2", par("path").stringValue(),
								par("prefix").stringValue(),
								i,
								config,
								run );
				}
				else
				{
					sprintf( strbuffer, "%s/%s%d-%s-%d.log", par("path").stringValue(),
								par("prefix").stringValue(),
								i,
								config,
								run );
				}

				FILE* file = NULL;
				file = fopen(strbuffer, "w");

				if( NULL == file )
					cRuntimeError("unable to open field for writing!");
//				else
//					printf( "opened file %s for writing\r\n", fileName );

				files.push_back( file );

				if( compress == 2 )
				{
					int bzerror;
					BZFILE* bzfile = NULL;

					bzfile = BZ2_bzWriteOpen( &bzerror, file, 9, 0, 0);

					if( BZ_OK == bzerror && bzfile != NULL )
					{
//						printf( "compressing %s with bz2\r\n", par("prefix").stringValue() );
					}
					else
						cRuntimeError("unable to open compressed field for writing");

					bzfiles.push_back( bzfile );
				}

				void* data = NULL;

				switch( format[i] )
				{
				case -8:
					data = new (std::nothrow) double[maxRecords];
					break;
				case -4:
					data = new (std::nothrow) float[maxRecords];
					break;
				case 8:
					data = new (std::nothrow) int64_t[maxRecords];
					break;
				case 18:
					data = new (std::nothrow) uint64_t[maxRecords];
					break;
				case 4:
					data = new (std::nothrow) int32_t[maxRecords];
					break;
				case 14:
					data = new (std::nothrow) uint32_t[maxRecords];
					break;
				case 2:
					data = new (std::nothrow) int16_t[maxRecords];
					break;
				case 12:
					data = new (std::nothrow) uint16_t[maxRecords];
					break;
				case 1:
					data = new (std::nothrow) int8_t[maxRecords];
					break;
				case 11:
					data = new (std::nothrow) uint8_t[maxRecords];
					break;
				default:
					cRuntimeError("unknown format code");
				}

				if( data != NULL )
					buffer.push_back( data );
				else
					cRuntimeError("Was unable to allocate buffer for instrument");
			}
		}
	}
}

void Instrument::finish()
{
	if( enabled )
	{
		dumpRecords();

		for( unsigned int i = 0; i < format.size(); i++ )
		{
			void* data = buffer[i];
			if( data == NULL )
				cRuntimeError("pointer to field buffer is NULL, this should never happen");

			switch( format[i] )
			{
			case -8:
				delete[] (double*)data;
				break;
			case -4:
				delete[] (float*)data;
				break;
			case 8:
				delete[] (int64_t*)data;
				break;
			case 18:
				delete[] (uint64_t*)data;
				break;
			case 4:
				delete[] (int32_t*)data;
				break;
			case 14:
				delete[] (uint32_t*)data;
				break;
			case 2:
				delete[] (int16_t*)data;
				break;
			case 12:
				delete[] (uint16_t*)data;
				break;
			case 1:
				delete[] (int8_t*)data;
				break;
			case 11:
				delete[] (uint8_t*)data;
				break;
			}
			if( compress == 2 )
			{
				int bzerror;
				BZ2_bzWriteClose( &bzerror, bzfiles[i], 0, NULL, NULL );
				if( BZ_OK != bzerror )
					cRuntimeError("failed to close compressed field");
	//			else
	//				printf("finished compressing %s field %d with bz2\r\n", par("prefix").stringValue(), i );
			}
			fclose( files[i] );
		}
		if( compress == 1 )
		{
			const char* config = simulation.getActiveEnvir()->getConfigEx()->getActiveConfigName();
			int run = simulation.getActiveEnvir()->getConfigEx()->getActiveRunNumber();

			char command[512];
			sprintf( command, "./compress %s %s %s %d", par("path").stringValue(),
						par("prefix").stringValue(),
						config,
						run );

			if( 0 != system( command ) )
				cRuntimeError("failed to compress results");
	//		else
	//			printf( "finished compressing %s fields with tar.gz\r\n", par("prefix").stringValue() );
		}
	}
}
/*
void Instrument::setField( unsigned int fieldNo, double values )
{
	if( format[fieldNo] == -8 )
	{
		//buffer[fieldNo][curRecord]
	}
}

void Instrument::setField( unsigned int fieldNo, float values )
{

}

void Instrument::setField( unsigned int fieldNo, int64_t values )
{

}

void Instrument::setField( unsigned int fieldNo, uint64_t values )
{

}

void Instrument::setField( unsigned int fieldNo, int32_t values )
{

}

void Instrument::setField( unsigned int fieldNo, uint32_t values )
{

}

void Instrument::setField( unsigned int fieldNo, int16_t values )
{

}

void Instrument::setField( unsigned int fieldNo, uint16_t values )
{

}
void Instrument::setField( unsigned int fieldNo, int8_t values )
{

}

void Instrument::setField( unsigned int fieldNo, uint8_t values )
{

}
*/

unsigned long Instrument::parseFormat(const char *s)
{
	unsigned long bytes = 0;
    while (isspace(*s)) s++;

    while (*s)
    {
    	int8_t value = 0;

    	if (!isdigit(*s))
    	    throw cRuntimeError("syntax error: type size expected (1,2,4,8)");

    	value = atoi(s);

    	while (isdigit(*s)) s++;

		char c = *s++;
        if( c == 'f' )
        {
        	bytes += value;
        	value = -1*value;
        }
        else if( c == 'u' )
        {
        	bytes += value;
        	value = 10+value;
        }
        else if ( c == 'i' )
        {
        	bytes += value;
        }
        else
        	throw cRuntimeError("syntax error: format code invalid (f,i,u)");

        format.push_back( value );

        while (isspace(*s)) s++;

        if (*s++!=',')
        	break;

        while (isspace(*s)) s++;
    }
    return bytes;
}

int Instrument::persistBuffer( int field, void* buffer, size_t size, size_t count )
{
	int length = count;
	if( compress == 2 )
	{
		length = count * size;
		int bzerror;
		BZ2_bzWrite( &bzerror, bzfiles[field], buffer, length );

		if( BZ_OK != bzerror )
			cRuntimeError("failed to write buffer to compressed field file");
//		else
//			printf("compressed %s field %d buffer with bz2\r\n", par("prefix").stringValue(), field );

		fflush( files[field] );

		length = 0;
	}
	else
	{
		length = length-fwrite( buffer, size, count, files[field] );
		fflush(files[field]);
//		printf("wrote buffer to disk for %s field %d", par("prefix").stringValue(), field );
	}
	return length;
}

void Instrument::dumpRecords()
{
	if( curRecord > 0 )
	{
		for( unsigned int i = 0; i < format.size(); i++ )
		{
			void* data = buffer[i];
			if( data == NULL )
				cRuntimeError("pointer to field buffer is NULL, this should never happen");

			if( true == first )
				if( 0 != persistBuffer( i, &format[i], sizeof(int8_t), 1 ) )
					cRuntimeError("failed to write format code to field buffer file");

			size_t length = ( curRecord < maxRecords) ? curRecord : maxRecords;
			size_t size = 0;

			switch( format[i] )
			{
			case -8:
				size = sizeof( double );
				break;
			case -4:
				size = sizeof( float );
				break;
			case 8:
				size = sizeof( int64_t );
				break;
			case 18:
				size = sizeof( uint64_t );
				break;
			case 4:
				size = sizeof( int32_t );
				break;
			case 14:
				size = sizeof( uint32_t );
				break;
			case 2:
				size = sizeof( int16_t );
				break;
			case 12:
				size = sizeof( uint16_t );
				break;
			case 1:
				size = sizeof( int8_t );
				break;
			case 11:
				size = sizeof( uint8_t );
				break;
			}

			if( 0 != persistBuffer( i, data, size, length ) )
				cRuntimeError("failed to write field buffer to file");
		}
		first = false;
		curRecord = 0;
	}
}

void Instrument::parseMessage(cMessage* msg)
{
	LoggerEvent* e = dynamic_cast<LoggerEvent*>(msg);
	if( NULL != e )
	{
		std::vector<double> vec = e->getRecord();

		if( vec.size() != format.size() )
			cRuntimeError("message did not contain expected amount of data");

		for( unsigned int i = 0; i < format.size(); i++ )
		{
			void* data = buffer[i];

			if( data == NULL )
				cRuntimeError("tried to parse field that had no buffer");

			switch ( format[i] )
			{
			case -8:
				((double*)data)[curRecord] = (double)vec[i];
				break;
			case -4:
				((float*)data)[curRecord] = (float)vec[i];
				break;
			case 8:
				((int64_t*)data)[curRecord] = (int64_t)vec[i];
				break;
			case 18:
				((uint64_t*)data)[curRecord] = (uint64_t)vec[i];
				break;
			case 4:
				((int32_t*)data)[curRecord] = (int32_t)vec[i];
				break;
			case 14:
				((uint32_t*)data)[curRecord] = (uint32_t)vec[i];
				break;
			case 2:
				((int16_t*)data)[curRecord] = (int16_t)vec[i];
				break;
			case 12:
				((uint16_t*)data)[curRecord] = (uint16_t)vec[i];
				break;
			case 1:
				((int8_t*)data)[curRecord] = (int8_t)vec[i];
				break;
			case 11:
				((uint8_t*)data)[curRecord] = (uint8_t)vec[i];
				break;
			}
		}
		curRecord++;
		if( curRecord >= maxRecords )
			dumpRecords();
	}
	else
		cRuntimeError("invalid message, must be LoggerEvent or child");
}

void Instrument::handleMessage(cMessage *msg)
{
	if( enabled && simTime() >= par("startTime") ) {
		if( msg->arrivedOn("in") )
		{
			parseMessage( msg );
		}
	}
	delete msg;
}


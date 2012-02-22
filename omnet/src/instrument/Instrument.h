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

#ifndef __INSTRUMENT_H__
#define __INSTRUMENT_H__

#include <omnetpp.h>
#include <vector>
#include <bzlib.h>
/**
 * TODO - Generated class
 */
class Instrument : public cSimpleModule
{
protected:
   	virtual void initialize(int stage);
	virtual void finish();
	virtual void handleMessage(cMessage *msg);
	virtual void dumpRecords();
	virtual int persistBuffer( int field, void* buffer, size_t size, size_t count );

	virtual unsigned long parseFormat(const char* fmt);
	virtual void parseMessage(cMessage* e);
/*
	void setField( unsigned int fieldNo, double values );
	void setField( unsigned int fieldNo, float values );

	void setField( unsigned int fieldNo, int64_t values );
	void setField( unsigned int fieldNo, uint64_t values );

	void setField( unsigned int fieldNo, int32_t values );
	void setField( unsigned int fieldNo, uint32_t values );

	void setField( unsigned int fieldNo, int16_t values );
	void setField( unsigned int fieldNo, uint16_t values );

	void setField( unsigned int fieldNo, int8_t values );
	void setField( unsigned int fieldNo, uint8_t values );
*/
	unsigned long curRecord;
 	unsigned long maxRecords;
	unsigned long maxBytes;
	unsigned long bufferedBytes;
	unsigned long recordBytes;
	bool enabled;
	bool readable;
	bool first;
	unsigned int compress;

	std::vector<void*> buffer;
   	std::vector<int8_t> format;
	std::vector<FILE*> files;
	std::vector<BZFILE*> bzfiles;
};

#endif

CXX = g++

TARGET = simulator
OBJECTS = simulator.o
CFLAGS = -c
LDFLAGS =
DEBUG = -g

all	: $(TARGET)

$(TARGET) : $(OBJECTS)
	$(CXX) $(DEBUG) -o $@ $(OBJECTS) $(LDFLAGS)

%.o : %.cc
	$(CXX) $(CFLAGS) $(DEBUG) $<

clean :
	rm *.o $(TARGET)

package com.example.app.services;

import com.example.app.entity.Person;

import java.util.List;
import java.util.Optional;

public interface PersonService {

    public List<Person> obtener();

    public void eliminar(Long id);

    public Person guardar(Person person);

    public Person Actualizar(Person person);

    Optional<Person> getPersonById(Long id);
}


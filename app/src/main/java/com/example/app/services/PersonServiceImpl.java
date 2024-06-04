package com.example.app.services;

import com.example.app.dao.PersonDao;
import com.example.app.entity.Person;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class PersonServiceImpl implements PersonService {

    @Autowired
    private PersonDao personDao;


    @Override
    public List<Person> obtener() {
        List<Person> person = personDao.findAll();
        if(personDao.findAll().toArray().length !=0)
            System.out.println("no hay lista");
        return person;
    }

    @Override
    public void eliminar(Long id) {
        personDao.deleteById(id);
    }

    @Override
    public Person guardar(Person p) {
        Person person = personDao.save(p);
        return person;
    }

    @Override
    public Person Actualizar(Person p) {
        Person person = personDao.save(p);
        return person;
    }

    @Override
    public Optional<Person> getPersonById(Long id) {

        return personDao.findById(id);
    }


    public List<Person> getAllPersons() {
        return personDao.findAll();
    }

}
